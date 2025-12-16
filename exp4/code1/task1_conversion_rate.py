#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
任务1：计算每个用户"从点击到购买"的转化率
仅考虑同商品的情况
"""

from pyspark import SparkContext
import sys

def calculate_conversion_rate(input_path, output_path):
    """
    计算用户点击到购买的转化率
    
    Args:
        input_path: 输入数据路径
        output_path: 输出结果路径
    """
    # 初始化SparkContext
    sc = SparkContext(appName="UserClickToBuyConversionRate")
    
    try:
        # 读取输入数据
        lines = sc.textFile(input_path)
        
        # 解析数据格式: (user_id, item_id, behavior, timestamp)
        def parse_line(line):
            parts = line.strip().split(',')
            return (int(parts[0]), int(parts[1]), parts[2], int(parts[3]))
        
        data = lines.map(parse_line)
        
        # 过滤出click行为，映射为(user_id, item_id) -> timestamp
        clicks = data.filter(lambda x: x[2] == "click") \
                     .map(lambda x: ((x[0], x[1]), x[3]))
        
        # 过滤出buy行为，映射为(user_id, item_id) -> timestamp
        buys = data.filter(lambda x: x[2] == "buy") \
                   .map(lambda x: ((x[0], x[1]), x[3]))
        
        # 找出有点击且有购买的商品（购买时间 > 点击时间）
        def has_valid_conversion(click_buy_pair):
            (user_item, (click_time, buy_time)) = click_buy_pair
            return buy_time > click_time
        
        # 连接点击和购买数据
        click_buy_pairs = clicks.join(buys)
        
        # 筛选出有效的转化（购买时间 > 点击时间）
        valid_conversions = click_buy_pairs.filter(has_valid_conversion)
        
        # 统计每个用户有转化的商品数
        user_converted_items = valid_conversions.map(lambda x: (x[0][0], 1)) \
                                               .reduceByKey(lambda a, b: a + b)
        
        # 统计每个用户点击过的商品数
        user_clicked_items = clicks.map(lambda x: (x[0][0], 1)) \
                                  .reduceByKey(lambda a, b: a + b)
        
        # 计算转化率（左连接，确保没有点击的用户也能被包含）
        def calculate_rate(clicked_count, converted_count):
            if converted_count is None:
                converted_count = 0
            if clicked_count is None or clicked_count == 0:
                return 0.0
            return round(converted_count / clicked_count, 2)
        
        # 全外连接确保所有用户都被包含
        all_users = user_clicked_items.fullOuterJoin(user_converted_items)
        
        # 计算转化率
        conversion_rates = all_users.map(lambda x: (x[0], calculate_rate(x[1][0], x[1][1])))
        
        # 保存结果
        conversion_rates.saveAsTextFile(output_path)
        
        # 收集并打印部分结果用于验证
        results = conversion_rates.collect()
        print("=== 用户点击到购买转化率结果 ===")
        for user_id, rate in sorted(results):
            print(f"用户 {user_id}: 转化率 = {rate}")
        
        print(f"\n总用户数: {len(results)}")
        
    finally:
        # 关闭SparkContext
        sc.stop()

def main():
    """主函数"""
    if len(sys.argv) >= 2:
        input_path = sys.argv[1]
    else:
        input_path = "data/user_behavior_logs.csv"  # 默认数据集路径
    
    if len(sys.argv) >= 3:
        output_path = sys.argv[2]
    else:
        output_path = "exp4/output/task1_conversion_rate"  # 默认输出路径
    
    calculate_conversion_rate(input_path, output_path)

if __name__ == "__main__":
    main()