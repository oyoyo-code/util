import numpy as np

def filter_circles(circles, tolerance=3, radius_threshold=0.2):
    """
    同一中心座標を持つ円を一つに絞り込む関数

    :param circles: 検出された円のリスト [[(中心x, 中心y), 半径], ...]
    :param tolerance: 中心座標が同一とみなす許容値（ピクセル）
    :param radius_threshold: 半径の閾値（全体の平均からの許容範囲）
    :return: フィルタリングされた円のリスト
    """
    if not circles:
        return []

    circles_array = np.array(circles, dtype=object)
    centers = np.array([circle[0] for circle in circles_array])
    radii = np.array([circle[1] for circle in circles_array])

    mean_radius = np.mean(radii)

    filtered_circles = []
    used_indices = set()

    for i, (center, radius) in enumerate(circles):
        if i in used_indices:
            continue

        distances = np.linalg.norm(centers - np.array(center), axis=1)
        similar_indices = np.where(distances <= tolerance)[0]

        similar_radii = radii[similar_indices]
        best_index = similar_indices[np.argmin(np.abs(similar_radii - mean_radius))]

        if abs(radii[best_index] - mean_radius) <= radius_threshold * mean_radius:
            filtered_circles.append(circles[best_index])

        used_indices.update(similar_indices)

    return filtered_circles

def filter_circles_in_rectangle(circles, x1, y1, x2, y2, tolerance=3, radius_threshold=0.2):
    """
    矩形内に中心がある円をフィルタリングし、同一中心座標を持つ円を一つに絞り込む関数

    :param circles: 検出された円のリスト [[(中心x, 中心y), 半径], ...]
    :param x1, y1: 矩形の左上座標
    :param x2, y2: 矩形の右下座標
    :param tolerance: 中心座標が同一とみなす許容値（ピクセル）
    :param radius_threshold: 半径の閾値（全体の平均からの許容範囲）
    :return: フィルタリングされた円のリスト
    """
    # 矩形内の円を選択
    circles_in_rectangle = [
        circle for circle in circles
        if x1 <= circle[0][0] <= x2 and y1 <= circle[0][1] <= y2
    ]

    # 選択された円に対してフィルタリングを適用
    return filter_circles(circles_in_rectangle, tolerance, radius_threshold)

# 使用例
detected_circles = [
    [(100, 100), 50],
    [(101, 101), 52],
    [(200, 200), 30],
    [(202, 198), 28],
    [(300, 300), 40],
]

# 矩形の定義
rect_x1, rect_y1 = 50, 50
rect_x2, rect_y2 = 250, 250

filtered_result = filter_circles_in_rectangle(detected_circles, rect_x1, rect_y1, rect_x2, rect_y2)
print("矩形内でフィルタリングされた結果:", filtered_result)