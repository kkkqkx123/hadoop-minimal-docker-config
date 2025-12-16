#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
任务2：统计每个用户的"加购后购买率"（Cart-to-Buy Conversion Rate）
仅考虑同商品，且cart时间 < buy时间
"""

from pyspark import SparkContext
import sys

def calculate_cart_to_buy_rate(input_path, output_path):
    """
    计算用户加购后购买率
    
    Args:
        input_path: 输入数据路径
        output_path: 输出结果路径
    """
    # 初始化SparkContext
    sc = SparkContext(appName="UserCartToBuyConversionRate")
    
    try:
        # 读取输入数据
        lines = sc.textFile(input_path)
        
        # 解析数据格式: (user_id, item_id, behavior, timestamp)
        def parse_line(line):
            parts = line.strip().split(',')
            return (int(parts[0]), int(parts[1]), parts[2], int(parts[3]))
        
        data = lines.map(parse_line)
        
        # 过滤出cart行为，映射为(user_id, item_id) -> timestamp
        carts = data.filter(lambda x: x[2] == "cart") \
                   .map(lambda x: ((x[0], x[1]), x[3]))
        
        # 过滤出buy行为，映射为(user_id, item_id) -> timestamp
        buys = data.filter(lambda x: x[2] == "buy") \
                   .map(lambda x: ((x[0], x[1]), x[3]))
        
        # 找出有加购且有购买的商品（购买时间 > 加购时间）
        def has_valid_cart_buy_conversion(cart_buy_pair):
            (user_item, (cart_time, buy_time)) = cart_buy_pair
            return buy_time > cart_time
        
        # 连接加购和购买数据
        cart_buy_pairs = carts.join(buys)
        
        # 筛选出有效的转化（购买时间 > 加购时间）
        valid_conversions = cart_buy_pairs.filter(has_valid_cart_buy_conversion)
        
        # 统计每个用户有加购后购买的商品数
        user_converted_items = valid_conversions.map(lambda x: (x[0][0], 1)) \
                                              .reduceByKey(lambda a, b: a + b)
        
        # 统计每个用户加购过的商品数
        user_carted_items = carts.map(lambda x: (x[0][0], 1)) \
                                 .reduceByKey(lambda a, b: a + b)
        
        # 计算加购后购买率（左连接，确保没有加购的用户也能被包含）
        def calculate_rate(carted_count, converted_count):
            if converted_count is None:
                converted_count = 0
            if carted_count is None or carted_count == 0:
                return 0.0
            return round(converted_count / carted_count, 2)
        
        # 全外连接确保所有用户都被包含
        all_users = user_carted_items.fullOuterJoin(user_converted_items)
        
        # 计算加购后购买率
        cart_to_buy_rates = all_users.map(lambda x: (x[0], calculate_rate(x[1][0], x[1][1])))
        
        # 保存结果
        cart_to_buy_rates.saveAsTextFile(output_path)
        
        # 收集并打印部分结果用于验证
        results = cart_to_buy_rates.collect()
        print("=== 用户加购后购买率结果 ===")
        for user_id, rate in sorted(results):
            print(f"用户 {user_id}: 加购后购买率 = {rate}")
        
        print(f"\n总用户数: {len(results)}")
        
        # 统计一些关键指标
        total_users = len(results)
        users_with_carts = sum(1 for _, rate in results if rate > 0)
        print(f"有加购行为的用户数: {users_with_carts}")
        print(f"加购用户占比: {round(users_with_carts/total_users*100, 2)}%")
        
    finally:
        # 关闭SparkContext
        sc.stop()

def main():
    """主函数"""
    if len(sys.argv) >= 3:
        input_path = sys.argv[1]
        output_path = sys.argv[2]
    else:
        input_path = "data/user_behavior_logs.csv"  # 默认数据集路径
        output_path = "output/task2_cart_to_buy_rate"     # 默认输出路径
    
    calculate_cart_to_buy_rate(input_path, output_path)

if __name__ == "__main__":
    main()