# Student Data Generation Strategy for Adaptive Scaffolding System

## 📋 Overview

This Python script generates synthetic student data for high school students (10th and 12th grade) in Karad, Maharashtra. The data is designed to train an ML model for an "Adaptive Scaffolding" system that predicts student engagement and cognitive load.

## 🎯 Purpose

The generated dataset contains realistic student profiles with intelligent correlations between various behavioral and academic metrics, enabling ML models to learn meaningful patterns for:
- **Student engagement prediction**
- **Cognitive load assessment**
- **Personalized learning interventions**
- **At-risk student identification**

## 📊 The 7 Survey Metrics (Pillars)

Every student record contains responses to the following dimensions:

1. **Q1 - Knowledge Tracing**: Confidence score (1-10) in a specific topic
2. **Q2 - Time-Series Patterns**: Frequency of phone checks during a 2-hour session (0, 1-3, 4-6, 7+ times)
3. **Q3 - Environmental Context**: Primary study inhibitor (Digital distractions, Noise, Tiredness, Lack of understanding, Chores)
4. **Q4 - Pedagogical Preference**: Most effective resource (Video, Solved Example, Textbook, 1-on-1 Chat)
5. **Q5 - Goal Orientation**: Primary goal (JEE/NEET/CET, 90%+ Boards, Just passing)
6. **Q6 - Cognitive Load**: Persistence in minutes before giving up on a hard problem (Numerical)
7. **Q7 - Social Context**: Frequency of peer/teacher discussion (Daily, Weekly, Rarely, Never)

## 🎓 Student Profiles

The generator creates three distinct student profiles with realistic correlations:

### 1. High-Performer Profile (30% of students)
- **Q1 (Confidence)**: ≥ 8
- **Q2 (Distractions)**: Low (0 or 1-3 phone checks)
- **Q6 (Persistence)**: High (20-45 minutes)
- **Characteristics**: Focused, confident, high persistence

### 2. At-Risk Profile (25% of students)
- **Q1 (Confidence)**: ≤ 3
- **Q2 (Distractions)**: High (4-6 or 7+ phone checks)
- **Q6 (Persistence)**: Low (2-10 minutes)
- **Characteristics**: Low confidence, easily distracted, gives up quickly

### 3. Average Profile (45% of students)
- **Q1 (Confidence)**: 4-7
- **Q2 (Distractions)**: Moderate
- **Q6 (Persistence)**: Moderate (10-20 minutes)
- **Characteristics**: Balanced performance, typical student behavior

## 🏫 Demographic Details

### Geography
- **Location**: Karad, Maharashtra

### Names
- Traditional Marathi first names and surnames
- Examples: Aditya Patil, Snehal Deshmukh, Rohan Kulkarni

### Institutes

**10th Grade Schools:**
- Tilak High School
- Shri Shivaji Vidyalaya
- Holy Family Convent
- Podar International

**12th Grade Colleges:**
- SGM College
- YCC
- Ligade-Patil Jr. College
- JK Academy

## 🔗 Data Correlation Logic

The script implements intelligent correlations to ensure ML models can learn meaningful patterns:

### Grade-Specific Patterns
- **10th Grade**: 85% weighted toward "90%+ Boards" goal orientation
- **12th Grade**: 75% weighted toward "JEE/NEET/CET" goal orientation

### Profile-Based Correlations
- High performers have low distractions and high persistence
- At-risk students have high distractions and low persistence
- Average students show moderate patterns across all metrics

## 📁 Output Files

The script generates three files:

1. **`student_data.csv`** - Production dataset (without metadata)
   - 1000 student records
   - 12 columns (all survey metrics + demographics)
   - Ready for ML model training

2. **`student_data_with_metadata.csv`** - Dataset with validation metadata
   - 1000 student records
   - 13 columns (includes Profile_Type for validation)
   - Useful for analysis and debugging

3. **`generation_report.txt`** - Detailed statistics report
   - Distribution analysis by profile type
   - Validation of correlation logic
   - Institute and goal orientation breakdowns

## 🚀 Usage

### Prerequisites
```bash
pip install pandas numpy
```

### Running the Script
```bash
python student_data_generator.py
```

### Configuration
You can modify the following parameters in the `main()` function:

```python
NUM_STUDENTS = 1000      # Total number of students to generate
GRADE_10_RATIO = 0.5     # 50% 10th grade, 50% 12th grade
OUTPUT_FILE = "student_data.csv"
```

## 📈 Sample Output

```
======================================================================
Student Data Generation Strategy - Adaptive Scaffolding System
======================================================================

Generating 1000 student records...
  - 10th Grade: 500 students
  - 12th Grade: 500 students

Location: Karad, Maharashtra
Generation Time: 2025-12-23 22:12:45

----------------------------------------------------------------------

[OK] Successfully generated 1000 student records

Data Distribution Summary:
----------------------------------------------------------------------

Grade Distribution:
10    500
12    500

Profile Type Distribution:
average           423
high_performer    314
at_risk           263

Goal Orientation (10th Grade):
90%+ Boards     439
JEE/NEET/CET     39
Just passing     22

Goal Orientation (12th Grade):
JEE/NEET/CET    379
90%+ Boards      88
Just passing     33
```

## 📊 Sample Data

| Student_ID | Name | Grade | Institute | Q1_Confidence_Score | Q2_Phone_Checks | Q3_Study_Inhibitor | Q4_Pedagogical_Preference | Q5_Goal_Orientation | Q6_Persistence_Minutes | Q7_Discussion_Frequency |
|------------|------|-------|-----------|---------------------|-----------------|-------------------|---------------------------|---------------------|------------------------|------------------------|
| STU_001 | Saurabh Londhe | 10 | Tilak High School | 6 | 0 | Noise | Textbook | 90%+ Boards | 13 | Weekly |
| STU_002 | Manasi Ingale | 10 | Podar International | 8 | 0 | Tiredness | Video | 90%+ Boards | 34 | Weekly |
| STU_003 | Vaibhav Ghuge | 10 | Shri Shivaji Vidyalaya | 6 | 4-6 | Noise | Video | 90%+ Boards | 17 | Rarely |

## 🔍 Validation

The script includes built-in validation through:
- **Profile Type Metadata**: Tracks which profile each student belongs to
- **Statistics Report**: Validates correlations are working correctly
- **Distribution Analysis**: Ensures demographic constraints are met

### Key Validation Metrics
- High performers: Mean confidence ~8.9, Mean persistence ~32 minutes
- At-risk students: Mean confidence ~2.0, Mean persistence ~6 minutes
- Average students: Mean confidence ~5.4, Mean persistence ~15 minutes

## 🎯 Use Cases

1. **ML Model Training**: Train adaptive scaffolding models to predict student engagement
2. **Pattern Recognition**: Identify at-risk students based on behavioral patterns
3. **Intervention Design**: Design personalized learning interventions
4. **Research**: Study correlations between student behavior and academic performance
5. **Prototype Testing**: Test educational technology systems with realistic data

## 📝 Notes

- All data is synthetic and generated using intelligent correlation logic
- Student names are randomly generated using traditional Marathi names
- The script uses a fixed random seed (42) for reproducibility
- Data distributions are designed to reflect realistic student populations

## 🤝 Contributing

To modify the generation logic:
1. Edit the profile generation methods (`generate_high_performer_profile`, etc.)
2. Adjust correlation weights in the `random.choices()` calls
3. Add new survey metrics by extending the student record structure

## 📄 License

This script is designed for educational and research purposes.

---

**Generated by**: Data Science Team  
**Last Updated**: 2025-12-23  
**Version**: 1.0
