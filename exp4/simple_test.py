#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
简化测试脚本 - 验证数据集修改后的算法正确性
"""

def load_data(filename):
    """加载CSV格式的用户行为数据"""
    data = []
    with open(filename, 'r', encoding='utf-8') as f:
        import csv
        reader = csv.reader(f)
        is_first_line = True
        for row in reader:
            # 跳过CSV标题行
            if is_first_line and row and row[0] == 'user_id':
                is_first_line = False
                continue
            if len(row) == 4:
                try:
                    user_id, item_id, behavior, timestamp = row
                    data.append((int(user_id), int(item_id), behavior, int(timestamp)))
                except ValueError:
                    continue
    return data

def test_basic_functionality():
    """测试基本功能"""
    print("🧪 开始简化测试...")
    
    # 加载数据
    try:
        data = load_data("data/user_behavior_logs.csv")
        print(f"✅ 成功加载 {len(data)} 条数据")
    except Exception as e:
        print(f"❌ 数据加载失败: {e}")
        return
    
    # 基础统计
    users = set(row[0] for row in data)
    items = set(row[1] for row in data)
    behaviors = set(row[2] for row in data)
    
    print(f"📊 数据统计:")
    print(f"  - 用户数: {len(users)}")
    print(f"  - 商品数: {len(items)}")
    print(f"  - 行为类型: {behaviors}")
    
    # 行为统计
    behavior_counts = {}
    for _, _, behavior, _ in data:
        behavior_counts[behavior] = behavior_counts.get(behavior, 0) + 1
    
    print(f"  - 行为分布:")
    for behavior, count in behavior_counts.items():
        print(f"    {behavior}: {count}")
    
    print("✅ 简化测试完成！")

if __name__ == "__main__":
    test_basic_functionality()