import cv2
import numpy as np
from collections import defaultdict

# 前述の他の関数（detect_circles, remove_duplicate_circles, detect_lines, is_line_inside_circles, find_tangent_line, rotate_image）はそのままです

def count_circles_in_rows(circles, min_distance=20):
    if len(circles) == 0:
        return "0x0", []

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

    # 各行の最大列数を計算
    max_cols = max(len(row) for row in rows)
    num_rows = len(rows)

    # 行列の枠を作成
    circle_matrix = [[0 for _ in range(max_cols)] for _ in range(num_rows)]

    # 円の位置を行列に記録
    for i, row in enumerate(rows):
        row_sorted = sorted(row, key=lambda c: c[0])  # X座標でソート
        if len(row) < max_cols:
            # 右詰めか左詰めかを判断
            if row_sorted[0][0] > centers[:, 0].mean():  # 行の平均X座標より右にあれば右詰め
                start_index = max_cols - len(row)
            else:
                start_index = 0
        else:
            start_index = 0
        
        for j, center in enumerate(row_sorted):
            circle_matrix[i][start_index + j] = 1

    return f"{num_rows}x{max_cols}", circle_matrix

def process_image(image_path, min_distance=20):
    image = cv2.imread(image_path)
    circles = detect_circles(image, min_distance)
    circles = remove_duplicate_circles(circles)
    lines = detect_lines(image)
    tangent_line = find_tangent_line(circles, lines)
    rotated_image, angle = rotate_image(image, tangent_line)
    rotated_circles = detect_circles(rotated_image, min_distance)
    rotated_circles = remove_duplicate_circles(rotated_circles)
    result, circle_matrix = count_circles_in_rows(rotated_circles, min_distance)
    return result, circle_matrix, angle

# 使用例
image_path = "path/to/your/image.jpg"
result, circle_matrix, rotation_angle = process_image(image_path)
print(f"円の配置: {result}")
print("円の行列表現:")
for row in circle_matrix:
    print(row)
print(f"回転角度: {rotation_angle:.2f}度")
