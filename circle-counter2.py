import cv2
import numpy as np

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
    lines = cv2.HoughLinesP(edges, 1, np.pi/180, threshold=100, minLineLength=100, maxLineGap=10)
    return lines

def find_nearest_line(circles, lines):
    if lines is None or len(circles) == 0:
        return None

    circle_centers = circles[:, :2]
    min_distance = float('inf')
    nearest_line = None

    for line in lines:
        x1, y1, x2, y2 = line[0]
        distances = np.abs((y2-y1)*circle_centers[:,0] - (x2-x1)*circle_centers[:,1] + x2*y1 - y2*x1) / np.sqrt((y2-y1)**2 + (x2-x1)**2)
        avg_distance = np.mean(distances)
        
        if avg_distance < min_distance:
            min_distance = avg_distance
            nearest_line = (x1, y1, x2, y2)

    return nearest_line

def rotate_coordinates(circles, angle, center):
    radians = np.radians(angle)
    cos_theta, sin_theta = np.cos(radians), np.sin(radians)
    
    # 中心を原点に移動
    translated = circles[:, :2] - center
    
    # 回転行列を適用
    rotated = np.column_stack((
        translated[:, 0] * cos_theta - translated[:, 1] * sin_theta,
        translated[:, 0] * sin_theta + translated[:, 1] * cos_theta
    ))
    
    # 元の位置に戻す
    rotated += center
    
    # 半径情報を元の配列から取得
    result = np.column_stack((rotated, circles[:, 2]))
    
    return result.astype(int)

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
    
    if nearest_line:
        x1, y1, x2, y2 = nearest_line
        angle = np.degrees(np.arctan2(y2 - y1, x2 - x1))
        if angle < -45:
            angle += 180
    else:
        angle = 0

    center = (image.shape[1] // 2, image.shape[0] // 2)
    rotated_circles = rotate_coordinates(circles, angle, center)
    result = count_circles_in_rows(rotated_circles, min_distance)
    return result, angle

# 使用例
image_path = "path/to/your/image.jpg"
result, rotation_angle = process_image(image_path)
print(f"円の配置: {result}")
print(f"回転角度: {rotation_angle:.2f}度")
