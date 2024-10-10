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

    # NumPy配列に変換
    circles_array = np.array(circles, dtype=object)
    centers = np.array([circle[0] for circle in circles_array])
    radii = np.array([circle[1] for circle in circles_array])

    # 全体の半径の平均を計算
    mean_radius = np.mean(radii)

    filtered_circles = []
    used_indices = set()

    for i, (center, radius) in enumerate(circles):
        if i in used_indices:
            continue

        # 同一中心座標を持つ円のインデックスを取得
        distances = np.linalg.norm(centers - np.array(center), axis=1)
        similar_indices = np.where(distances <= tolerance)[0]

        # 同一中心座標を持つ円の中から、平均半径に最も近い円を選択
        similar_radii = radii[similar_indices]
        best_index = similar_indices[np.argmin(np.abs(similar_radii - mean_radius))]

        # 選択された円の半径が閾値内にある場合のみ追加
        if abs(radii[best_index] - mean_radius) <= radius_threshold * mean_radius:
            filtered_circles.append(circles[best_index])

        used_indices.update(similar_indices)

    return filtered_circles

# 使用例
detected_circles = [
    [(100, 100), 50],
    [(101, 101), 52],
    [(200, 200), 30],
    [(202, 198), 28],
    [(300, 300), 40],
]

filtered_result = filter_circles(detected_circles)
print("フィルタリング結果:", filtered_result)