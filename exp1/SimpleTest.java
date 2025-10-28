import java.util.*;

/**
 * 简单的测试程序，用于验证排序逻辑
 */
public class SimpleTest {
    
    static class StudentScore {
        String studentId;
        int chineseScore;
        int mathScore;
        int englishScore;
        int totalScore;
        
        public StudentScore(String studentId, int chineseScore, int mathScore, int englishScore) {
            this.studentId = studentId;
            this.chineseScore = chineseScore;
            this.mathScore = mathScore;
            this.englishScore = englishScore;
            this.totalScore = chineseScore + mathScore + englishScore;
        }
        
        @Override
        public String toString() {
            return studentId + " 语文：" + chineseScore + ".0, 数学：" + mathScore + ".0, 英语：" + englishScore + ".0, 总分：" + totalScore + ".0";
        }
    }
    
    public static void main(String[] args) {
        System.out.println("===== 学生成绩Top10排序逻辑测试 =====");
        
        // 读取测试数据
        List<StudentScore> students = new ArrayList<>();
        
        // 测试数据1
        students.add(new StudentScore("1001", 85, 92, 78));
        students.add(new StudentScore("1002", 90, 88, 95));
        students.add(new StudentScore("1003", 78, 85, 92));
        students.add(new StudentScore("1004", 92, 95, 88));
        students.add(new StudentScore("1005", 88, 90, 85));
        students.add(new StudentScore("1006", 95, 85, 90));
        students.add(new StudentScore("1007", 82, 88, 92));
        students.add(new StudentScore("1008", 90, 92, 88));
        students.add(new StudentScore("1009", 85, 90, 95));
        students.add(new StudentScore("1010", 92, 88, 85));
        students.add(new StudentScore("1011", 88, 95, 90));
        students.add(new StudentScore("1012", 95, 90, 88));
        students.add(new StudentScore("1013", 90, 85, 92));
        students.add(new StudentScore("1014", 85, 92, 90));
        students.add(new StudentScore("1015", 92, 90, 88));
        
        // 排序：总分降序，总分相同则数学成绩降序
        students.sort((a, b) -> {
            if (a.totalScore != b.totalScore) {
                return Integer.compare(b.totalScore, a.totalScore); // 降序
            }
            return Integer.compare(b.mathScore, a.mathScore); // 降序
        });
        
        // 输出Top10
        System.out.println("Top10 学生成绩：");
        for (int i = 0; i < Math.min(10, students.size()); i++) {
            System.out.println((i + 1) + ". " + students.get(i));
        }
        
        System.out.println("\n===== 测试完成 =====");
    }
}