#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
任务3：识别"高曝光低加购"商品（High-Click Low-Cart Items）
找出被大量用户点击但极少被加入购物车的商品
"""

from pyspark import SparkContext
import sys

def identify_high_click_low_cart_items(input_path, output_path):
    """
    识别高曝光低加购商品
    
    Args:
        input_path: 输入数据路径
        output_path: 输出结果路径
    """
    # 初始化SparkContext
    sc = SparkContext(appName="HighClickLowCartItems")
    
    try:
        # 读取输入数据
        lines = sc.textFile(input_path)
        
        # 解析数据格式: (user_id, item_id, behavior, timestamp)
        def parse_line(line):
            parts = line.strip().split(',')
            return (int(parts[0]), int(parts[1]), parts[2], int(parts[3]))
        
        data = lines.map(parse_line)
        
        # 筛选条件常量
        MIN_CLICKS = 10      # 最少点击次数
        MAX_CART_RATE = 0.2  # 最大加购转化率
        
        # 统计每个商品的点击次数
        item_clicks = data.filter(lambda x: x[2] == "click") \
                         .map(lambda x: (x[1], 1)) \
                         .reduceByKey(lambda a, b: a + b)
        
        # 统计每个商品的加购次数
        item_carts = data.filter(lambda x: x[2] == "cart") \
                        .map(lambda x: (x[1], 1)) \
                        .reduceByKey(lambda a, b: a + b)
        
        # 为没有加购的商品设置加购次数为0
        # 首先获取所有有点击的商品ID
        all_items_with_clicks = item_clicks.map(lambda x: x[0]).distinct()
        
        # 将加购数据与所有商品进行左外连接，缺失的设为0
        item_carts_complete = item_carts.rightOuterJoin(all_items_with_clicks.map(lambda x: (x, None))) \
                                       .map(lambda x: (x[0], x[1][0] if x[1][0] is not None else 0))
        
        # 连接点击和加购数据
        item_stats = item_clicks.leftOuterJoin(item_carts_complete) \
                                .map(lambda x: (x[0], (x[1][0], x[1][1] if x[1][1] is not None else 0)))
        
        # 计算加购转化率并应用筛选条件
        def filter_high_click_low_cart(item_stat):
            item_id, (click_count, cart_count) = item_stat
            
            # 应用筛选条件
            if click_count >= MIN_CLICKS:
                cart_conversion_rate = round(cart_count / click_count, 2) if click_count > 0 else 0.0
                
                if cart_conversion_rate <= MAX_CART_RATE:
                    return (item_id, click_count, cart_count, cart_conversion_rate)
            
            return None
        
        # 应用筛选并过滤掉None值
        high_click_low_cart_items = item_stats.map(filter_high_click_low_cart) \
                                             .filter(lambda x: x is not None)
        
        # 按加购转化率升序排序（转化率最低的最优先）
        sorted_items = high_click_low_cart_items.sortBy(lambda x: x[3])
        
        # 保存结果
        sorted_items.saveAsTextFile(output_path)
        
        # 收集并打印结果用于验证
        results = sorted_items.collect()
        print("=== 高曝光低加购商品分析结果 ===")
        print(f"筛选条件: 点击次数 ≥ {MIN_CLICKS}, 加购转化率 ≤ {MAX_CART_RATE}")
        print(f"找到 {len(results)} 个符合条件的商品\n")
        
        print("商品ID | 点击次数 | 加购次数 | 加购转化率")
        print("-" * 45)
        for item_id, click_count, cart_count, conversion_rate in results[:20]:  # 只显示前20个
            print(f"{item_id:6d} | {click_count:8d} | {cart_count:8d} | {conversion_rate:10.2f}")
        
        if len(results) > 20:
            print(f"\n... 还有 {len(results) - 20} 个商品")
        
        # 统计信息
        if results:
            avg_click_count = sum(r[1] for r in results) / len(results)
            avg_cart_rate = sum(r[3] for r in results) / len(results)
            print(f"\n统计信息:")
            print(f"平均点击次数: {avg_click_count:.1f}")
            print(f"平均加购转化率: {avg_cart_rate:.3f}")
        
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
        output_path = "output/task3"  # 默认输出路径
    
    identify_high_click_low_cart_items(input_path, output_path)

if __name__ == "__main__":
    main()