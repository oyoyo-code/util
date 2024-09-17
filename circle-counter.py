import cv2
import numpy as np
from scipy.spatial.distance import cdist

def detect_circles(image, min_distance=20):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    circles = cv2.HoughCircles(gray, cv2.HOUGH_GRADIENT, dp=1, minDist=min_distance,
                               param1=50, param2=30, minRadius=0, maxRadius=0)
    if circles is None:
        return []
    return np.round(circles[0, :]).astype("int")

def detect_lines(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    edges = cv2.Canny(gray, 50, 150, apertureSize=3)
    lines = cv2.HoughLines(edges, 1, np.pi/180, 200)
    return lines

def find_nearest_line(circles, lines):
    if lines is None or len(circles) == 0:
        return None

    circle_centers = circles[:, :2]
    min_distance = float('inf')
    nearest_line = None

    for line in lines:
        rho, theta = line[0]
        a = np.cos(theta)
        b = np.sin(theta)
        x0, y0 = a * rho, b * rho
        x1, y1 = int(x0 + 1000 * (-b)), int(y0 + 1000 * (a))
        x2, y2 = int(x0 - 1000 * (-b)), int(y0 - 1000 * (a))
        
        distances = np.abs((y2-y1)*circle_centers[:,0] - (x2-x1)*circle_centers[:,1] + x2*y1 - y2*x1) / np.sqrt((y2-y1)**2 + (x2-x1)**2)
        avg_distance = np.mean(distances)
        
        if avg_distance < min_distance:
            min_distance = avg_distance
            nearest_line = (rho, theta)

    return nearest_line

def rotate_image(image, line):
    if line is None:
        return image, 0

    rho, theta = line
    angle = np.degrees(theta) - 90
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
    lines = detect_lines(image)
    nearest_line = find_nearest_line(circles, lines)
    rotated_image, angle = rotate_image(image, nearest_line)
    rotated_circles = detect_circles(rotated_image, min_distance)
    result = count_circles_in_rows(rotated_circles, min_distance)
    return result, angle

# 使用例
image_path = "path/to/your/image.jpg"
result, rotation_angle = process_image(image_path)
print(f"円の配置: {result}")
print(f"回転角度: {rotation_angle:.2f}度")
