#!/bin/bash

echo "准备PageRank测试数据..."
echo "========================"

echo "转换测试数据格式..."
# 将测试数据转换为PageRank输入格式
# 格式：页面ID\t初始PageRank值\t出链列表

cat > exp3/dataset/processed/test_pagerank_input.txt << 'EOF'
1\t1.0\t2,3
2\t1.0\t3
3\t1.0\t1
4\t1.0\t1,2
EOF

echo "测试数据转换完成！"
echo "测试数据预览："
cat exp3/dataset/processed/test_pagerank_input.txt

echo ""
echo "运行PageRank测试..."
echo "cd exp3 && bash run_pagerank.sh processed/test_pagerank_input.txt /output/pagerank_test 5"