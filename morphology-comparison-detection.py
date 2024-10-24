import cv2
import numpy as np

def detect_objects_by_morphology(image_path):
    # 画像の読み込み
    image = cv2.imread(image_path)
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    # 二値化処理
    _, binary = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY_INV)
    
    # カーネルの定義
    kernel_small = np.ones((3,3), np.uint8)
    kernel_medium = np.ones((7,7), np.uint8)
    kernel_large = np.ones((15,15), np.uint8)
    
    # ノイズ除去のための処理
    # まず小さなノイズを除去
    denoised = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel_small)
    
    # 文字や線などの細かい要素を除去
    text_removed = cv2.morphologyEx(denoised, cv2.MORPH_OPEN, kernel_medium)
    
    # 物体領域の強調
    dilated = cv2.dilate(text_removed, kernel_medium, iterations=2)
    
    # 物体の中心部分の抽出
    eroded = cv2.erode(dilated, kernel_medium, iterations=3)
    
    # 物体領域の復元
    reconstructed = cv2.dilate(eroded, kernel_medium, iterations=3)
    
    # 差分による物体検出
    # 膨張処理と収縮処理の差分を取ることで、物体の境界を検出
    diff = cv2.absdiff(dilated, eroded)
    
    # 物体の中心を見つけるための処理
    center_markers = cv2.morphologyEx(eroded, cv2.MORPH_CLOSE, kernel_large)
    
    # 結果画像の準備
    result_image = image.copy()
    detected_objects = []
    
    # ラベリング処理で物体を個別に検出
    num_labels, labels, stats, centroids = cv2.connectedComponentsWithStats(center_markers)
    
    # 背景ラベルを除外し、面積でソート
    object_stats = [(i, stat) for i, stat in enumerate(stats) if i != 0]  # 背景(i=0)を除外
    object_stats.sort(key=lambda x: x[1][4], reverse=True)  # 面積でソート
    
    # 上位3つの物体を処理
    for i, (label_idx, stat) in enumerate(object_stats[:3]):
        x, y = stat[0], stat[1]
        w, h = stat[2], stat[3]
        
        # 小さすぎる物体は除外
        if w * h < 100:  # 最小サイズのしきい値
            continue
            
        # 矩形の描画
        cv2.rectangle(result_image, (x, y), (x+w, y+h), (0, 255, 0), 2)
        
        # 検出情報の保存
        detected_objects.append({
            'x': x,
            'y': y,
            'width': w,
            'height': h,
            'center': (x + w//2, y + h//2)
        })
    
    # 処理過程の可視化
    process_images = {
        'Original': image,
        'Denoised': denoised,
        'Text Removed': text_removed,
        'Dilated': dilated,
        'Eroded': eroded,
        'Reconstructed': reconstructed,
        'Difference': diff,
        'Center Markers': center_markers,
        'Result': result_image
    }
    
    # 処理過程の表示
    for title, img in process_images.items():
        if len(img.shape) == 2:  # グレースケールの場合
            img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
        cv2.imshow(title, img)
    
    cv2.waitKey(0)
    cv2.destroyAllWindows()
    
    return detected_objects, result_image

# 使用例
def main():
    image_path = 'path_to_your_image.jpg'  # 画像パスを指定
    objects, result = detect_objects_by_morphology(image_path)
    
    # 検出結果の出力
    print("検出された物体の情報:")
    for i, obj in enumerate(objects, 1):
        print(f"物体 {i}:")
        print(f"  左上座標: ({obj['x']}, {obj['y']})")
        print(f"  幅: {obj['width']}")
        print(f"  高さ: {obj['height']}")
        print(f"  中心座標: {obj['center']}")
        print()

if __name__ == "__main__":
    main()
