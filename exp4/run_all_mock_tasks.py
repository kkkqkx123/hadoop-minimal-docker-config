#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
综合模拟脚本：同时运行三个任务的模拟
模拟exp4中所有PySpark任务的输出
"""

import sys
import random
import os

def mock_all_tasks():
    """运行所有任务的模拟"""
    
    # 确保输出目录存在
    os.makedirs('output', exist_ok=True)
    
    print("=" * 60)
    print("开始运行所有任务的模拟...")
    print("=" * 60)
    
    # 任务1：用户点击到购买转化率
    print("\n🎯 任务1：用户点击到购买转化率")
    print("-" * 40)
    
    random.seed(42)
    task1_results = []
    for user_id in range(1, 51):
        if user_id <= 10:
            rate = round(random.uniform(0.3, 0.8), 2)
        elif user_id <= 25:
            rate = round(random.uniform(0.1, 0.4), 2)
        elif user_id <= 40:
            rate = round(random.uniform(0.0, 0.2), 2)
        else:
            rate = round(random.uniform(0.0, 0.1), 2)
        task1_results.append((user_id, rate))
    
    # 显示前10个用户
    for user_id, rate in task1_results[:10]:
        print(f"用户 {user_id}: 转化率 = {rate}")
    print("...")
    print(f"总用户数: {len(task1_results)}")
    
    # 保存任务1结果
    with open('output/task1_conversion_rate_mock.txt', 'w') as f:
        for user_id, rate in task1_results:
            f.write(f"({user_id}, {rate})\n")
    
    # 任务2：用户加购后购买率
    print("\n🛒 任务2：用户加购后购买率")
    print("-" * 40)
    
    random.seed(42)
    task2_results = []
    for user_id in range(1, 51):
        if user_id <= 8:
            rate = round(random.uniform(0.6, 1.0), 2)
        elif user_id <= 20:
            rate = round(random.uniform(0.3, 0.7), 2)
        elif user_id <= 35:
            rate = round(random.uniform(0.1, 0.4), 2)
        else:
            rate = round(random.uniform(0.0, 0.2), 2)
        task2_results.append((user_id, rate))
    
    # 显示前10个用户
    for user_id, rate in task2_results[:10]:
        print(f"用户 {user_id}: 加购后购买率 = {rate}")
    print("...")
    
    total_users = len(task2_results)
    users_with_carts = sum(1 for _, rate in task2_results if rate > 0)
    print(f"总用户数: {total_users}")
    print(f"有加购行为的用户数: {users_with_carts}")
    print(f"加购用户占比: {round(users_with_carts/total_users*100, 2)}%")
    
    # 保存任务2结果
    with open('output/task2_cart_to_buy_rate_mock.txt', 'w') as f:
        for user_id, rate in task2_results:
            f.write(f"({user_id}, {rate})\n")
    
    # 任务3：高曝光低加购商品
    print("\n📊 任务3：高曝光低加购商品分析")
    print("-" * 40)
    
    MIN_CLICKS = 10
    MAX_CART_RATE = 0.2
    
    print(f"筛选条件: 点击次数 ≥ {MIN_CLICKS}, 加购转化率 ≤ {MAX_CART_RATE}")
    
    random.seed(42)
    task3_results = []
    
    # 生成20个符合条件的商品
    for i in range(20):
        item_id = random.randint(100, 999)
        click_count = random.randint(15, 80)
        max_cart_count = int(click_count * MAX_CART_RATE)
        cart_count = random.randint(0, max_cart_count)
        conversion_rate = round(cart_count / click_count, 2)
        task3_results.append((item_id, click_count, cart_count, conversion_rate))
    
    # 按转化率升序排序
    task3_results.sort(key=lambda x: x[3])
    
    print(f"找到 {len(task3_results)} 个符合条件的商品\n")
    
    print("商品ID | 点击次数 | 加购次数 | 加购转化率")
    print("-" * 45)
    for item_id, click_count, cart_count, conversion_rate in task3_results:
        print(f"{item_id:6d} | {click_count:8d} | {cart_count:8d} | {conversion_rate:10.2f}")
    
    # 统计信息
    if task3_results:
        avg_click_count = sum(r[1] for r in task3_results) / len(task3_results)
        avg_cart_rate = sum(r[3] for r in task3_results) / len(task3_results)
        print(f"\n统计信息:")
        print(f"平均点击次数: {avg_click_count:.1f}")
        print(f"平均加购转化率: {avg_cart_rate:.3f}")
    
    # 保存任务3结果
    with open('output/task3_high_click_low_cart_mock.txt', 'w') as f:
        for item_id, click_count, cart_count, conversion_rate in task3_results:
            f.write(f"({item_id}, {click_count}, {cart_count}, {conversion_rate})\n")
    
    print("\n" + "=" * 60)
    print("✅ 所有任务模拟完成！")
    print("=" * 60)
    print("\n输出文件:")
    print("- output/task1_conversion_rate_mock.txt")
    print("- output/task2_cart_to_buy_rate_mock.txt") 
    print("- output/task3_high_click_low_cart_mock.txt")

if __name__ == "__main__":
    mock_all_tasks()