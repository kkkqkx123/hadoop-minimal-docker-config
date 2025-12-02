实验内容：

PageRank计算

用python计算网页的pagerank值。

1、初始值

- 每个页面设置相同的PR值

- Google的PageRank算法给每个页面的PR初始值为1。

2、迭代递归计算（收敛）

Google不断的重复计算每个页面的PageRank。那么经过不断的重复计算，这些页面的PR值会趋向于稳定，也就是收敛的状态。

3、在具体应用中如何确定收敛标准？

- 每个页面的PR值和上一次计算的PR相等。

- 设定一个差值指标（0.001），当所有页面和上一次计算的PR差值平均小于该标准时，则收敛。

因此需要对 PageRank公式进行修正，即在简单公式的基础上增加阻尼系数（damping factor）q， q一般取值q=0.85。

数据集见exp3\dataset\wiki-edges.txt

exp3\dataset\wiki-vertices.txt。

只需要输出结果即可。输出格式与 PageRankReducer.java 保持一致