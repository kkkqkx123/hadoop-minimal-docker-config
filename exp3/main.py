#!/usr/bin/env python3
"""
PageRank算法Python实现
与Java MapReduce版本保持相同的输出格式
"""

import sys
import os

def load_graph(edges_file, vertices_file):
    """
    加载图数据
    Args:
        edges_file: 边文件路径 (source_id\ttarget_id)
        vertices_file: 顶点文件路径 (vertex_id\ttitle)
    Returns:
        graph: {page_id: {'out_links': [target_ids], 'title': title}}
        pages: {page_id: title}
    """
    graph = {}
    pages = {}
    
    # 加载顶点信息
    with open(vertices_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split('\t')
            if len(parts) >= 2:
                page_id = parts[0].strip()
                title = parts[1].strip()
                pages[page_id] = title
                graph[page_id] = {'out_links': [], 'title': title}
    
    # 加载边信息
    with open(edges_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split('\t')
            if len(parts) >= 2:
                source_id = parts[0].strip()
                target_id = parts[1].strip()
                
                # 确保源页面在图中
                if source_id not in graph:
                    graph[source_id] = {'out_links': [], 'title': source_id}
                
                # 添加出链
                if target_id not in graph[source_id]['out_links']:
                    graph[source_id]['out_links'].append(target_id)
    
    return graph, pages

def pagerank_iteration(graph, pagerank, damping_factor=0.85, teleportation=0.15):
    """
    执行一次PageRank迭代
    Args:
        graph: 图结构
        pagerank: 当前PageRank值 {page_id: rank}
        damping_factor: 阻尼系数
        teleportation: 跳转概率
    Returns:
        new_pagerank: 新的PageRank值
        total_diff: 总变化量
    """
    new_pagerank = {}
    total_diff = 0.0
    num_pages = len(graph)
    
    # 初始化新的PageRank值
    for page_id in graph:
        new_pagerank[page_id] = 0.0
    
    # 计算每个页面的贡献值
    for page_id, page_data in graph.items():
        current_rank = pagerank.get(page_id, 1.0)
        out_links = page_data['out_links']
        
        if out_links:
            # 如果有出链，将PageRank值分配给所有出链
            contribution = current_rank * damping_factor / len(out_links)
            for target_id in out_links:
                if target_id in new_pagerank:
                    new_pagerank[target_id] += contribution
        else:
            # 如果没有出链，将PageRank值平均分配给所有页面
            contribution = current_rank * damping_factor / num_pages
            for target_id in new_pagerank:
                new_pagerank[target_id] += contribution
    
    # 添加跳转概率并归一化
    for page_id in new_pagerank:
        new_pagerank[page_id] += teleportation
        # 计算变化量
        old_rank = pagerank.get(page_id, 1.0)
        total_diff += abs(new_pagerank[page_id] - old_rank)
    
    return new_pagerank, total_diff

def pagerank_python(edges_file, vertices_file, max_iterations=100, convergence_threshold=0.001):
    """
    Python实现的PageRank算法
    Args:
        edges_file: 边文件路径
        vertices_file: 顶点文件路径
        max_iterations: 最大迭代次数
        convergence_threshold: 收敛阈值
    Returns:
        final_pagerank: 最终的PageRank值
    """
    # 加载图数据
    graph, pages = load_graph(edges_file, vertices_file)
    
    # 初始化PageRank值
    pagerank = {}
    num_pages = len(graph)
    initial_rank = 1.0
    
    for page_id in graph:
        pagerank[page_id] = initial_rank
    
    print(f"Loaded {num_pages} pages")
    print(f"Initial PageRank value: {initial_rank}")
    print(f"Damping factor: 0.85")
    print(f"Teleportation: 0.15")
    print(f"Convergence threshold: {convergence_threshold}")
    print("-" * 50)
    
    # 迭代计算
    for iteration in range(max_iterations):
        new_pagerank, total_diff = pagerank_iteration(graph, pagerank)
        
        avg_diff = total_diff / num_pages
        print(f"Iteration {iteration + 1}: Average difference = {avg_diff:.6f}")
        
        # 检查收敛
        if avg_diff < convergence_threshold:
            print(f"Converged at iteration {iteration + 1}")
            break
        
        pagerank = new_pagerank
    
    return pagerank, graph

def save_pagerank_results(pagerank, graph, output_file):
    """
    保存PageRank结果，格式与Java版本保持一致
    Args:
        pagerank: PageRank值
        graph: 图结构
        output_file: 输出文件路径
    """
    with open(output_file, 'w', encoding='utf-8') as f:
        # 按PageRank值降序排序
        sorted_pages = sorted(pagerank.items(), key=lambda x: x[1], reverse=True)
        
        for page_id, rank in sorted_pages:
            out_links = graph[page_id]['out_links']
            
            # 构建输出格式：pageId\tpageRank[\toutLink1,outLink2,...]
            output = f"{page_id}\t{rank:.6f}"
            
            if out_links:
                output += "\t" + ",".join(out_links)
            
            f.write(output + "\n")

def main():
    """主函数"""
    # 设置文件路径
    edges_file = "dataset/wiki-edges.txt"
    vertices_file = "dataset/wiki-vertices.txt"
    output_file = "pagerank_results.txt"
    
    # 检查文件是否存在
    if not os.path.exists(edges_file):
        print(f"Error: {edges_file} not found")
        return
    
    if not os.path.exists(vertices_file):
        print(f"Error: {vertices_file} not found")
        return
    
    # 运行PageRank算法
    print("Starting PageRank calculation...")
    final_pagerank, graph = pagerank_python(edges_file, vertices_file)
    
    # 保存结果
    save_pagerank_results(final_pagerank, graph, output_file)
    
    print("-" * 50)
    print(f"PageRank calculation completed!")
    print(f"Results saved to: {output_file}")
    
    # 显示前10个结果
    print("\nTop 10 pages by PageRank:")
    sorted_pages = sorted(final_pagerank.items(), key=lambda x: x[1], reverse=True)
    for i, (page_id, rank) in enumerate(sorted_pages[:10]):
        title = graph[page_id]['title']
        print(f"{i+1:2d}. {title[:50]:<50} (ID: {page_id[:20]}...) - PR: {rank:.6f}")

if __name__ == "__main__":
    main()