import cv2
import numpy as np
from collections import defaultdict

def detect_circles(image, min_distance=20):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    circles = cv2.HoughCircles(gray, cv2.HOUGH_GRADIENT, dp=1, minDist=min_distance,
                               param1=50, param2=30, minRadius=0, maxRadius=0)
    if circles is None:
        return []
    return np.round(circles[0, :]).astype("int")

def remove_duplicate_circles(circles, distance_threshold=3):
    if len(circles) == 0:
        return circles
    
    unique_circles = []
    for circle in circles:
        is_duplicate = False
        for unique_circle in unique_circles:
            if np.linalg.norm(circle[:2] - unique_circle[:2]) <= distance_threshold:
                if circle[2] > unique_circle[2]:  # 直径が大きい方を削除
                    is_duplicate = True
                else:
                    unique_circles.remove(unique_circle)
                break
        if not is_duplicate:
            unique_circles.append(circle)
    
    return np.array(unique_circles)

def detect_lines(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    edges = cv2.Canny(gray, 50, 150, apertureSize=3)
    lines = cv2.HoughLinesP(edges, 1, np.pi/180, threshold=100, minLineLength=100, maxLineGap=10)
    return lines

def is_line_inside_circles(line, circles):
    x1, y1, x2, y2 = line
    midpoint = ((x1 + x2) / 2, (y1 + y2) / 2)
    for circle in circles:
        cx, cy, r = circle
        if np.linalg.norm(np.array(midpoint) - np.array([cx, cy])) < r:
            return True
    return False

def find_tangent_line(circles, lines):
    if lines is None or len(circles) == 0:
        return None

    line_scores = defaultdict(int)
    for i, line in enumerate(lines):
        x1, y1, x2, y2 = line[0]
        if is_line_inside_circles(line[0], circles):
            continue
        for circle in circles:
            cx, cy, r = circle
            distance = np.abs((y2-y1)*cx - (x2-x1)*cy + x2*y1 - y2*x1) / np.sqrt((y2-y1)**2 + (x2-x1)**2)
            if abs(distance - r) < 3:  # 3ピクセルの許容範囲で接線とみなす
                line_scores[i] += 1

    if not line_scores:
        return None

    best_line_index = max(line_scores, key=line_scores.get)
    return lines[best_line_index][0]

def rotate_image(image, line):
    if line is None:
        return image, 0

    x1, y1, x2, y2 = line
    angle = np.degrees(np.arctan2(y2 - y1, x2 - x1))
    if angle < -45:
        angle += 180

    center = (image.shape[1] // 2, image.shape[0] // 2)
    rotation_matrix = cv2.getRotationMatrix2D(center, angle, 1.0)
    rotated = cv2.warpAffine(image, rotation_matrix, (image.shape[1], image.shape[0]))
    return rotated, angle

def count_circles_in_rows(circles, min_distance=20):
    if len(circles) == 0:
        return "0x0"

    centers = circles[:, :2]
    centers = centers[centers[:, 1].argsort()]

    rows = []
    current_row = [centers[0]]
    for center in centers[1:]:
        if abs(center[1] - current_row[-1][1]) <= min_distance:
            current_row.append(center)
        else:
            rows.append(current_row)
            current_row = [center]
    rows.append(current_row)

    row_counts = [len(row) for row in rows]
    return f"{len(row_counts)}x{max(row_counts)}"

def process_image(image_path, min_distance=20):
    image = cv2.imread(image_path)
    circles = detect_circles(image, min_distance)
    circles = remove_duplicate_circles(circles)
    lines = detect_lines(image)
    tangent_line = find_tangent_line(circles, lines)
    rotated_image, angle = rotate_image(image, tangent_line)
    rotated_circles = detect_circles(rotated_image, min_distance)
    rotated_circles = remove_duplicate_circles(rotated_circles)
    result = count_circles_in_rows(rotated_circles, min_distance)
    return result, angle

# 使用例
image_path = "path/to/your/image.jpg"
result, rotation_angle = process_image(image_path)
print(f"円の配置: {result}")
print(f"回転角度: {rotation_angle:.2f}度")
