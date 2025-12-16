#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
本地测试脚本 - 在不依赖Spark的情况下验证算法逻辑
"""

import csv
from collections import defaultdict
import time

def load_data(filename):
    """加载测试数据"""
    data = []
    with open(filename, 'r', encoding='utf-8') as f:
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
                    continue  # 跳过格式不正确的行
    return data

def test_task1(data):
    """测试任务1：用户点击到购买转化率"""
    print("\n=== 任务1测试：用户点击到购买转化率 ===")
    
    # 统计每个用户点击和购买的商品
    user_clicks = defaultdict(set)  # 用户点击的商品集合
    user_conversions = defaultdict(set)  # 用户有转化的商品集合（点击后购买）
    
    # 先按用户-商品分组，收集行为
    user_item_behaviors = defaultdict(list)
    for user_id, item_id, behavior, timestamp in data:
        user_item_behaviors[(user_id, item_id)].append((behavior, timestamp))
    
    # 分析每个用户-商品的行为序列
    for (user_id, item_id), behaviors in user_item_behaviors.items():
        has_click = False
        click_time = None
        
        # 按时间排序
        behaviors.sort(key=lambda x: x[1])
        
        for behavior, timestamp in behaviors:
            if behavior == "click":
                has_click = True
                click_time = timestamp
            elif behavior == "buy" and has_click and timestamp > click_time:
                user_conversions[user_id].add(item_id)
                break  # 找到转化就可以停止了
        
        # 统计点击的商品
        if any(b[0] == "click" for b in behaviors):
            user_clicks[user_id].add(item_id)
    
    # 计算转化率
    results = []
    all_users = set(user_clicks.keys()) | set(user_conversions.keys())
    
    for user_id in all_users:
        clicked_count = len(user_clicks[user_id])
        converted_count = len(user_conversions[user_id])
        
        if clicked_count == 0:
            conversion_rate = 0.0
        else:
            conversion_rate = round(converted_count / clicked_count, 2)
        
        results.append((user_id, conversion_rate))
        print(f"用户 {user_id}: 点击商品 {clicked_count} 个，转化商品 {converted_count} 个，转化率 = {conversion_rate}")
    
    return results

def test_task2(data):
    """测试任务2：用户加购后购买率"""
    print("\n=== 任务2测试：用户加购后购买率 ===")
    
    # 统计每个用户加购和购买的商品
    user_carts = defaultdict(set)  # 用户加购的商品集合
    user_cart_conversions = defaultdict(set)  # 用户有加购转化的商品集合（加购后购买）
    
    # 先按用户-商品分组，收集行为
    user_item_behaviors = defaultdict(list)
    for user_id, item_id, behavior, timestamp in data:
        user_item_behaviors[(user_id, item_id)].append((behavior, timestamp))
    
    # 分析每个用户-商品的行为序列
    for (user_id, item_id), behaviors in user_item_behaviors.items():
        has_cart = False
        cart_time = None
        
        # 按时间排序
        behaviors.sort(key=lambda x: x[1])
        
        for behavior, timestamp in behaviors:
            if behavior == "cart":
                has_cart = True
                cart_time = timestamp
            elif behavior == "buy" and has_cart and timestamp > cart_time:
                user_cart_conversions[user_id].add(item_id)
                break  # 找到转化就可以停止了
        
        # 统计加购的商品
        if any(b[0] == "cart" for b in behaviors):
            user_carts[user_id].add(item_id)
    
    # 计算加购后购买率
    results = []
    all_users = set(user_carts.keys()) | set(user_cart_conversions.keys())
    
    for user_id in all_users:
        carted_count = len(user_carts[user_id])
        converted_count = len(user_cart_conversions[user_id])
        
        if carted_count == 0:
            cart_to_buy_rate = 0.0
        else:
            cart_to_buy_rate = round(converted_count / carted_count, 2)
        
        results.append((user_id, cart_to_buy_rate))
        print(f"用户 {user_id}: 加购商品 {carted_count} 个，加购后购买商品 {converted_count} 个，加购购买率 = {cart_to_buy_rate}")
    
    return results

def test_task3(data):
    """测试任务3：高曝光低加购商品识别"""
    print("\n=== 任务3测试：高曝光低加购商品识别 ===")
    
    MIN_CLICKS = 10
    MAX_CART_RATE = 0.2
    
    # 统计每个商品的点击和加购次数
    item_clicks = defaultdict(int)
    item_carts = defaultdict(int)
    
    for user_id, item_id, behavior, timestamp in data:
        if behavior == "click":
            item_clicks[item_id] += 1
        elif behavior == "cart":
            item_carts[item_id] += 1
    
    # 找出符合条件的商品
    results = []
    all_items = set(item_clicks.keys()) | set(item_carts.keys())
    
    for item_id in all_items:
        click_count = item_clicks[item_id]
        cart_count = item_carts[item_id]
        
        if click_count >= MIN_CLICKS:
            cart_conversion_rate = round(cart_count / click_count, 2) if click_count > 0 else 0.0
            
            if cart_conversion_rate <= MAX_CART_RATE:
                results.append((item_id, click_count, cart_count, cart_conversion_rate))
                print(f"商品 {item_id}: 点击 {click_count} 次，加购 {cart_count} 次，加购转化率 = {cart_conversion_rate}")
    
    # 按转化率升序排序
    results.sort(key=lambda x: x[3])
    
    print(f"\n找到 {len(results)} 个符合条件的商品")
    return results

def main():
    """主函数"""
    print("🧪 开始本地算法测试...")
    
    # 加载测试数据
    try:
        data = load_data("data/user_behavior_logs.csv")
        print(f"加载了 {len(data)} 条测试数据")
        
        # 显示前几条数据
        print("\n前5条数据样本:")
        for i, record in enumerate(data[:5]):
            print(f"  {i+1}. user_id={record[0]}, item_id={record[1]}, behavior={record[2]}, timestamp={record[3]}")
        
    except FileNotFoundError:
        print("❌ 测试数据文件 data/user_behavior_logs.csv 不存在，请先准备数据文件")
        return
    
    # 执行任务测试
    start_time = time.time()
    
    results1 = test_task1(data)
    results2 = test_task2(data)
    results3 = test_task3(data)
    
    end_time = time.time()
    
    # 输出总结
    print(f"\n{'='*60}")
    print("📊 本地测试总结")
    print(f"{'='*60}")
    print(f"测试数据量: {len(data)} 条记录")
    print(f"任务1结果数: {len(results1)} 个用户")
    print(f"任务2结果数: {len(results2)} 个用户")
    print(f"任务3结果数: {len(results3)} 个商品")
    print(f"总执行时间: {end_time - start_time:.3f} 秒")
    
    print(f"\n✅ 本地算法验证完成!")
    print("这些结果可以与Spark执行结果进行对比，验证算法的正确性。")

if __name__ == "__main__":
    main()