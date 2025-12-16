#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成测试数据用于验证三个任务的正确性
数据格式: (user_id, item_id, behavior, timestamp)
"""

import random
import time

def generate_test_data(output_file, num_records=1000, num_users=100, num_items=50):
    """
    生成测试数据
    
    Args:
        output_file: 输出文件路径
        num_records: 记录总数
        num_users: 用户数量
        num_items: 商品数量
    """
    behaviors = ["click", "cart", "buy"]
    base_timestamp = int(time.time() * 1000)  # 当前时间戳（毫秒）
    
    with open(output_file, 'w', encoding='utf-8') as f:
        for i in range(num_records):
            user_id = random.randint(1, num_users)
            item_id = random.randint(1, num_items)
            
            # 根据业务逻辑调整行为概率
            # 点击行为占比最高，加购次之，购买最少
            rand = random.random()
            if rand < 0.7:  # 70% 点击
                behavior = "click"
            elif rand < 0.9:  # 20% 加购
                behavior = "cart"
            else:  # 10% 购买
                behavior = "buy"
            
            # 生成时间戳，确保行为的时间顺序合理性
            timestamp = base_timestamp + random.randint(0, 86400000)  # 24小时内随机时间
            
            # 写入数据
            f.write(f"{user_id},{item_id},{behavior},{timestamp}\n")
    
    print(f"生成测试数据完成: {num_records} 条记录")
    print(f"用户数: {num_users}, 商品数: {num_items}")

def generate_specific_test_cases(output_file):
    """
    生成特定的测试用例，确保覆盖各种边界情况
    """
    base_timestamp = int(time.time() * 1000)
    
    test_cases = [
        # 用户1: 有点击有购买（应该显示转化率）
        (1, 1, "click", base_timestamp),
        (1, 1, "buy", base_timestamp + 1000),
        (1, 2, "click", base_timestamp + 2000),
        (1, 2, "cart", base_timestamp + 3000),
        (1, 2, "buy", base_timestamp + 4000),
        
        # 用户2: 只有点击没有购买（转化率应该为0）
        (2, 3, "click", base_timestamp + 5000),
        (2, 4, "click", base_timestamp + 6000),
        (2, 5, "click", base_timestamp + 7000),
        
        # 用户3: 有加购有购买（应该显示加购购买率）
        (3, 6, "cart", base_timestamp + 8000),
        (3, 6, "buy", base_timestamp + 9000),
        (3, 7, "cart", base_timestamp + 10000),
        (3, 8, "cart", base_timestamp + 11000),
        (3, 8, "buy", base_timestamp + 12000),
        
        # 用户4: 只有加购没有购买（加购购买率应该为0）
        (4, 9, "cart", base_timestamp + 13000),
        (4, 10, "cart", base_timestamp + 14000),
        (4, 11, "cart", base_timestamp + 15000),
        
        # 商品1: 高点击低加购（应该出现在任务3结果中）
        (5, 12, "click", base_timestamp + 16000),
        (6, 12, "click", base_timestamp + 17000),
        (7, 12, "click", base_timestamp + 18000),
        (8, 12, "click", base_timestamp + 19000),
        (9, 12, "click", base_timestamp + 20000),
        (10, 12, "click", base_timestamp + 21000),
        (11, 12, "click", base_timestamp + 22000),
        (12, 12, "click", base_timestamp + 23000),
        (13, 12, "click", base_timestamp + 24000),
        (14, 12, "click", base_timestamp + 25000),
        (15, 12, "cart", base_timestamp + 26000),  # 只有一次加购
        
        # 商品2: 高点击高加购（不应该出现在任务3结果中）
        (16, 13, "click", base_timestamp + 27000),
        (17, 13, "click", base_timestamp + 28000),
        (18, 13, "click", base_timestamp + 29000),
        (19, 13, "click", base_timestamp + 30000),
        (20, 13, "click", base_timestamp + 31000),
        (21, 13, "cart", base_timestamp + 32000),
        (22, 13, "cart", base_timestamp + 33000),
        (23, 13, "cart", base_timestamp + 34000),
        (24, 13, "cart", base_timestamp + 35000),
        
        # 商品3: 低点击（不应该出现在任务3结果中）
        (25, 14, "click", base_timestamp + 36000),
        (26, 14, "cart", base_timestamp + 37000),
    ]
    
    with open(output_file, 'w', encoding='utf-8') as f:
        for user_id, item_id, behavior, timestamp in test_cases:
            f.write(f"{user_id},{item_id},{behavior},{timestamp}\n")
    
    print(f"生成特定测试用例完成: {len(test_cases)} 条记录")

def main():
    """主函数"""
    # 生成主要测试数据
    generate_test_data("test_data.txt", num_records=2000, num_users=200, num_items=100)
    
    # 生成特定测试用例
    generate_specific_test_cases("test_cases.txt")
    
    print("\n测试数据生成完成!")
    print("文件说明:")
    print("- test_data.txt: 主要测试数据，包含2000条随机记录")
    print("- test_cases.txt: 特定测试用例，包含边界情况")

if __name__ == "__main__":
    main()