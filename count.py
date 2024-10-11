import math

def count_circles(circles):
    if not circles:
        return 0, 0

    # 中心座標のみを抽出
    centers = [circle[0] for circle in circles]
    
    # x座標とy座標のリストを作成
    x_coords = [center[0] for center in centers]
    y_coords = [center[1] for center in centers]

    # y座標でソートし、各行の円を特定
    sorted_centers = sorted(centers, key=lambda c: c[1])
    rows = []
    current_row = [sorted_centers[0]]
    
    for center in sorted_centers[1:]:
        if abs(center[1] - current_row[0][1]) < 10:  # 同じ行とみなす閾値
            current_row.append(center)
        else:
            rows.append(current_row)
            current_row = [center]
    rows.append(current_row)

    # 行数を計算
    num_rows = len(rows)

    # 列数を計算
    max_x_diff = max(max(x_coords) - min(x_coords) for row in rows)
    avg_radius = sum(circle[1] for circle in circles) / len(circles)
    num_columns = math.ceil(max_x_diff / (2 * avg_radius)) + 1

    return num_rows, num_columns

# テスト用のデータ
test_circles = [
    [(10, 10), 5],
    [(30, 10), 5],
    [(50, 10), 5],
    [(70, 10), 5],
    [(10, 30), 5],
    [(30, 30), 5],
    [(50, 30), 5],
    [(70, 30), 5]
]

rows, columns = count_circles(test_circles)
print(f"行数: {rows}")
print(f"列数: {columns}")