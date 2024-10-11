import numpy as np

def calculate_perpendicular_points(start_point, end_point):
    # 線分Aのベクトルを計算
    vector_a = end_point - start_point
    
    # 線分Aの中点（交点）を計算
    midpoint = start_point + vector_a / 2
    
    # 線分Aに直交するベクトルを計算（90度回転）
    perpendicular_vector = np.array([-vector_a[1], vector_a[0]])
    
    # ベクトルの正規化（単位ベクトル化）
    perpendicular_unit_vector = perpendicular_vector / np.linalg.norm(perpendicular_vector)
    
    # 線分Aの長さを計算
    length_a = np.linalg.norm(vector_a)
    
    # 交点から線分Aの長さの2倍の距離にある点を計算
    point_plus = midpoint + perpendicular_unit_vector * length_a * 2
    point_minus = midpoint - perpendicular_unit_vector * length_a * 2
    
    return point_plus, point_minus

# 使用例
start_point = np.array([1, 1])
end_point = np.array([5, 5])

point_plus, point_minus = calculate_perpendicular_points(start_point, end_point)

print(f"線分Aの始点: {start_point}")
print(f"線分Aの終点: {end_point}")
print(f"線分Bのプラス方向の点: {point_plus}")
print(f"線分Bのマイナス方向の点: {point_minus}")