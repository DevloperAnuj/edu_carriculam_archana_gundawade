# Student Data Generation - Quick Start Guide

## 🚀 Quick Start (3 Steps)

### Step 1: Install Dependencies
```bash
pip install -r requirements.txt
```

### Step 2: Generate Student Data
```bash
python student_data_generator.py
```

This will create:
- `student_data.csv` - Production dataset (1000 students)
- `student_data_with_metadata.csv` - Dataset with profile metadata
- `generation_report.txt` - Statistics report

### Step 3: Validate & Analyze Data
```bash
python analyze_data.py
```

This will:
- Validate all correlations are working correctly
- Analyze patterns by profile and grade
- Export summary statistics to `data_summary.txt`

## 📊 What You Get

### Production Dataset (`student_data.csv`)
- **1000 student records** (500 from 10th grade, 500 from 12th grade)
- **12 columns**: Demographics + 7 Survey Metrics
- **Ready for ML training**

### Columns:
1. `Student_ID` - Unique identifier (STU_001 to STU_1000)
2. `Name` - Traditional Marathi name
3. `Grade` - 10 or 12
4. `Institute` - School/College name
5. `Location` - Karad, Maharashtra
6. `Q1_Confidence_Score` - Confidence in topic (1-10)
7. `Q2_Phone_Checks` - Distraction frequency (0, 1-3, 4-6, 7+)
8. `Q3_Study_Inhibitor` - Primary obstacle
9. `Q4_Pedagogical_Preference` - Preferred learning resource
10. `Q5_Goal_Orientation` - Academic goal
11. `Q6_Persistence_Minutes` - Time before giving up
12. `Q7_Discussion_Frequency` - Social learning frequency

## 🎯 Student Profiles

The data includes three realistic profiles:

### High-Performer (30%)
- Confidence: 8-10
- Distractions: Low (0 or 1-3 phone checks)
- Persistence: 20-45 minutes
- **Use Case**: Model successful learning patterns

### At-Risk (25%)
- Confidence: 1-3
- Distractions: High (4-6 or 7+ phone checks)
- Persistence: 2-10 minutes
- **Use Case**: Identify students needing intervention

### Average (45%)
- Confidence: 4-7
- Distractions: Moderate
- Persistence: 10-20 minutes
- **Use Case**: Baseline for comparison

## 🔍 Validation Results

All correlations are **100% validated**:
- ✓ High performers have low distractions
- ✓ At-risk students have high distractions
- ✓ 10th grade: 87.8% focused on "90%+ Boards"
- ✓ 12th grade: 75.8% focused on "JEE/NEET/CET"

## 📈 Sample Data Preview

| Student_ID | Name | Grade | Q1_Confidence | Q2_Phone_Checks | Q6_Persistence |
|------------|------|-------|---------------|-----------------|----------------|
| STU_001 | Saurabh Londhe | 10 | 6 | 0 | 13 |
| STU_002 | Manasi Ingale | 10 | 8 | 0 | 34 |
| STU_003 | Vaibhav Ghuge | 10 | 6 | 4-6 | 17 |

## 🎓 Use Cases

1. **ML Model Training** - Train adaptive scaffolding models
2. **Pattern Recognition** - Identify at-risk students
3. **Intervention Design** - Create personalized learning paths
4. **Research** - Study student behavior correlations
5. **Prototype Testing** - Test educational technology

## ⚙️ Customization

Edit `student_data_generator.py` to customize:

```python
# In main() function:
NUM_STUDENTS = 1000      # Change total students
GRADE_10_RATIO = 0.5     # Change grade distribution
```

## 📝 Files Generated

After running both scripts, you'll have:

```
SurvayScrapper/
├── student_data.csv                    # Production dataset
├── student_data_with_metadata.csv      # Dataset with profile types
├── generation_report.txt               # Generation statistics
├── data_summary.txt                    # Analysis summary
├── student_data_generator.py           # Main generator script
├── analyze_data.py                     # Analysis script
├── requirements.txt                    # Dependencies
└── README.md                           # Full documentation
```

## 🤝 Next Steps

1. **Load the data** in your ML framework (pandas, scikit-learn, TensorFlow, etc.)
2. **Explore patterns** using the analysis script
3. **Train your model** on the 7 survey metrics
4. **Predict** student engagement and cognitive load
5. **Deploy** adaptive scaffolding interventions

## 💡 Tips

- Use `student_data_with_metadata.csv` for analysis and validation
- Use `student_data.csv` for production ML training
- The data is reproducible (fixed random seed = 42)
- All correlations are intentionally designed for ML learning

## 📚 Documentation

See `README.md` for complete documentation including:
- Detailed survey metric descriptions
- Correlation logic explanation
- Profile generation algorithms
- Validation methodology

---

**Happy ML Training! 🚀**
