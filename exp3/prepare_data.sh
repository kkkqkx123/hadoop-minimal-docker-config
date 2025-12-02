#!/bin/bash

echo "准备PageRank输入数据..."
echo "========================"

# 检查输入文件
if [ ! -f "exp3/dataset/wiki-vertices.txt" ]; then
    echo "错误：未找到wiki-vertices.txt文件！"
    echo "请确保文件位于exp3/dataset/目录下"
    exit 1
fi

echo "创建临时处理目录..."
mkdir -p exp3/dataset/processed

echo ""
echo "转换数据格式..."
# 将wiki-vertices.txt转换为PageRank输入格式
# 格式：页面ID\t1.0\t出链列表（初始为空）
awk '{
    print $1 "\t1.0\t"
}' exp3/dataset/wiki-vertices.txt > exp3/dataset/processed/pagerank_input.txt

echo "转换完成！"
echo "输入数据预览："
head -5 exp3/dataset/processed/pagerank_input.txt

echo ""
echo "统计信息："
echo "总页面数: $(wc -l < exp3/dataset/processed/pagerank_input.txt)"
echo "数据大小: $(du -h exp3/dataset/processed/pagerank_input.txt | cut -f1)"

echo ""
echo "数据准备完成！"
echo "现在可以运行PageRank计算："
echo "cd exp3 && bash run_pagerank.sh processed/pagerank_input.txt /output/pagerank 10"