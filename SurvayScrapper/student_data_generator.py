"""
Student Data Generation Strategy for Adaptive Scaffolding System
==================================================================

Context & Objective:
Generate synthetic data for high school students (10th and 12th grade) in Karad, Maharashtra.
This data is designed to train an ML model for an "Adaptive Scaffolding" system that predicts 
student engagement and cognitive load.

Author: Data Science Team
Date: 2025-12-23
"""

import pandas as pd
import numpy as np
import random
from typing import Dict, List, Tuple
from datetime import datetime


class StudentDataGenerator:
    """
    Generates synthetic student data with intelligent correlations
    for ML model training in adaptive scaffolding systems.
    """
    
    # Marathi first names (traditional)
    FIRST_NAMES = [
        "Aditya", "Snehal", "Priya", "Rohan", "Ananya", "Arjun", "Pooja", "Siddharth",
        "Tanvi", "Aniket", "Shruti", "Omkar", "Sakshi", "Vaibhav", "Manasi", "Pratik",
        "Rutuja", "Akash", "Vaishnavi", "Nikhil", "Ashwini", "Sanket", "Neha", "Rahul",
        "Priyanka", "Abhishek", "Shweta", "Karan", "Pallavi", "Ganesh", "Madhuri", "Suraj",
        "Sanika", "Vishal", "Kavita", "Amol", "Tejal", "Saurabh", "Gauri", "Chetan",
        "Swapnil", "Archana", "Mayur", "Deepali", "Sachin", "Sonali", "Yogesh", "Apurva",
        "Tushar", "Vrushali", "Dnyanesh", "Sayali", "Mahesh", "Ashlesha", "Rohit", "Jayashree"
    ]
    
    # Marathi surnames (traditional)
    SURNAMES = [
        "Patil", "Deshmukh", "Kulkarni", "Pawar", "Jadhav", "Shinde", "More", "Kamble",
        "Salve", "Gaikwad", "Bhosale", "Sawant", "Kale", "Yadav", "Chavan", "Mane",
        "Thorat", "Kadam", "Nikam", "Sutar", "Lokhande", "Ghuge", "Shelke", "Raut",
        "Mohite", "Dhaygude", "Kumbhar", "Londhe", "Ingale", "Bhagat", "Shirke", "Waghmare"
    ]
    
    # 10th Grade Institutes
    INSTITUTES_10TH = [
        "Tilak High School",
        "Shri Shivaji Vidyalaya",
        "Holy Family Convent",
        "Podar International"
    ]
    
    # 12th Grade Institutes
    INSTITUTES_12TH = [
        "SGM College",
        "YCC",
        "Ligade-Patil Jr. College",
        "JK Academy"
    ]
    
    # Q2: Phone check frequency options (every student checks phone at least once)
    PHONE_CHECK_FREQ = ["1-3", "4-6", "7+"]
    
    # Q3: Study inhibitors
    STUDY_INHIBITORS = [
        "Digital distractions",
        "Noise",
        "Tiredness",
        "Lack of understanding",
        "Chores"
    ]
    
    # Q4: Pedagogical preferences
    PEDAGOGICAL_PREFS = [
        "Video",
        "Solved Example",
        "Textbook",
        "1-on-1 Chat"
    ]
    
    # Q5: Goal orientations
    GOAL_ORIENTATIONS_10TH = ["90%+ Boards", "JEE/NEET/CET", "Just passing"]
    GOAL_ORIENTATIONS_12TH = ["JEE/NEET/CET", "90%+ Boards", "Just passing"]
    
    # Q7: Discussion frequency
    DISCUSSION_FREQ = ["Daily", "Weekly", "Rarely", "Never"]

    # Q8: Learning style (VARK model)
    LEARNING_STYLES = ["Visual", "Auditory", "Kinesthetic", "Read-Write"]

    # Q9: AI tool usage frequency
    AI_TOOL_USAGE = ["Never", "Occasionally", "Regularly", "Daily"]

    # Q11: Dashboard motivation
    DASHBOARD_MOTIVATION = ["Yes", "No", "Doesn't matter"]

    # Q12: Teacher visibility comfort
    TEACHER_VISIBILITY = [
        "Yes I'd want that",
        "No I prefer privacy",
        "Only if I choose",
    ]

    # Q13: Data privacy preference
    DATA_PRIVACY_PREF = [
        "Device only (no cloud)",
        "School servers only",
        "I don't mind",
    ]

    # Q14: Hardest subject
    HARDEST_SUBJECTS = ["Physics", "Mathematics", "Chemistry", "Biology", "Computer Science"]

    # Q15: Help-seeking behaviour
    HELP_SEEKING = [
        "Search YouTube",
        "Ask a friend",
        "Ask a teacher",
        "Give up",
        "Use ChatGPT/AI",
    ]

    def __init__(self, num_students: int = 1000, grade_10_ratio: float = 0.5):
        """
        Initialize the student data generator.
        
        Args:
            num_students: Total number of students to generate
            grade_10_ratio: Ratio of 10th grade students (0.5 = 50%)
        """
        self.num_students = num_students
        self.grade_10_ratio = grade_10_ratio
        self.num_10th = int(num_students * grade_10_ratio)
        self.num_12th = num_students - self.num_10th
        
        # Set random seed for reproducibility
        np.random.seed(42)
        random.seed(42)
    
    def generate_name(self) -> str:
        """Generate a traditional Marathi name."""
        first_name = random.choice(self.FIRST_NAMES)
        surname = random.choice(self.SURNAMES)
        return f"{first_name} {surname}"
    
    def generate_high_performer_profile(self) -> Dict:
        """
        Generate data for a high-performer student.
        
        Logic:
        - Q1 (Confidence) >= 8
        - Q2 (Distractions) low (1-3 checks, rarely 4-6)
        - Q6 (Persistence) high (20-45 mins)
        """
        confidence = np.random.randint(8, 11)  # 8-10
        
        # Low distractions (85% chance of 1-3, 15% chance of 4-6)
        phone_checks = random.choices(
            ["1-3", "4-6"],
            weights=[0.85, 0.15]
        )[0]
        
        # High persistence (20-45 minutes)
        persistence = np.random.randint(20, 46)
        
        # Prefer effective resources (Video or Solved Example)
        pedagogical_pref = random.choices(
            self.PEDAGOGICAL_PREFS,
            weights=[0.4, 0.4, 0.1, 0.1]
        )[0]
        
        # Less likely to have "Lack of understanding" as inhibitor
        inhibitor = random.choices(
            self.STUDY_INHIBITORS,
            weights=[0.3, 0.2, 0.2, 0.1, 0.2]
        )[0]
        
        # More likely to discuss frequently
        discussion = random.choices(
            self.DISCUSSION_FREQ,
            weights=[0.5, 0.3, 0.15, 0.05]
        )[0]
        
        return {
            "confidence": confidence,
            "phone_checks": phone_checks,
            "inhibitor": inhibitor,
            "pedagogical_pref": pedagogical_pref,
            "persistence": persistence,
            "discussion": discussion
        }
    
    def generate_at_risk_profile(self) -> Dict:
        """
        Generate data for an at-risk student.
        
        Logic:
        - Q1 (Confidence) <= 3
        - Q2 (Distractions) high (4-6 or 7+)
        - Q6 (Persistence) low (2-10 mins)
        """
        confidence = np.random.randint(1, 4)  # 1-3
        
        # High distractions (60% chance of 4-6, 40% chance of 7+)
        phone_checks = random.choices(
            ["4-6", "7+"],
            weights=[0.6, 0.4]
        )[0]
        
        # Low persistence (2-10 minutes)
        persistence = np.random.randint(2, 11)
        
        # Prefer less effective resources or need help
        pedagogical_pref = random.choices(
            self.PEDAGOGICAL_PREFS,
            weights=[0.3, 0.2, 0.1, 0.4]  # Higher weight on 1-on-1 Chat
        )[0]
        
        # More likely to have "Lack of understanding" or "Digital distractions"
        inhibitor = random.choices(
            self.STUDY_INHIBITORS,
            weights=[0.4, 0.1, 0.2, 0.25, 0.05]
        )[0]
        
        # Less likely to discuss
        discussion = random.choices(
            self.DISCUSSION_FREQ,
            weights=[0.1, 0.2, 0.4, 0.3]
        )[0]
        
        return {
            "confidence": confidence,
            "phone_checks": phone_checks,
            "inhibitor": inhibitor,
            "pedagogical_pref": pedagogical_pref,
            "persistence": persistence,
            "discussion": discussion
        }
    
    def generate_average_profile(self) -> Dict:
        """
        Generate data for an average student (middle ground).
        
        Logic:
        - Q1 (Confidence) 4-7
        - Q2 (Distractions) moderate (mostly 1-3 or 4-6)
        - Q6 (Persistence) moderate (10-20 mins)
        """
        confidence = np.random.randint(4, 8)  # 4-7
        
        # Moderate distractions (40% 1-3, 50% 4-6, 10% 7+)
        phone_checks = random.choices(
            self.PHONE_CHECK_FREQ,
            weights=[0.40, 0.50, 0.10]
        )[0]
        
        # Moderate persistence (10-20 minutes)
        persistence = np.random.randint(10, 21)
        
        # Balanced pedagogical preference
        pedagogical_pref = random.choice(self.PEDAGOGICAL_PREFS)
        
        # Balanced inhibitors
        inhibitor = random.choice(self.STUDY_INHIBITORS)
        
        # Moderate discussion frequency
        discussion = random.choices(
            self.DISCUSSION_FREQ,
            weights=[0.2, 0.4, 0.3, 0.1]
        )[0]
        
        return {
            "confidence": confidence,
            "phone_checks": phone_checks,
            "inhibitor": inhibitor,
            "pedagogical_pref": pedagogical_pref,
            "persistence": persistence,
            "discussion": discussion
        }
    
    def generate_student_record(self, student_id: int, grade: int) -> Dict:
        """
        Generate a complete student record with correlated attributes.
        
        Args:
            student_id: Unique student identifier
            grade: 10 or 12
            
        Returns:
            Dictionary containing all student attributes
        """
        # Determine student profile type (30% high-performer, 25% at-risk, 45% average)
        profile_type = random.choices(
            ["high_performer", "at_risk", "average"],
            weights=[0.30, 0.25, 0.45]
        )[0]
        
        # Generate profile-specific attributes
        if profile_type == "high_performer":
            profile_data = self.generate_high_performer_profile()
        elif profile_type == "at_risk":
            profile_data = self.generate_at_risk_profile()
        else:
            profile_data = self.generate_average_profile()
        
        # Generate goal orientation based on grade
        if grade == 10:
            # 85% toward "90%+ Boards" for 10th grade
            goal = random.choices(
                self.GOAL_ORIENTATIONS_10TH,
                weights=[0.85, 0.10, 0.05]
            )[0]
        else:
            # 75% toward "JEE/NEET/CET" for 12th grade
            goal = random.choices(
                self.GOAL_ORIENTATIONS_12TH,
                weights=[0.75, 0.20, 0.05]
            )[0]
        
        # Select institute based on grade
        institute = random.choice(
            self.INSTITUTES_10TH if grade == 10 else self.INSTITUTES_12TH
        )
        
        # ── Q8–Q15: New survey questions ─────────────────────────────────────

        # Q9 first — needed by Q10 and Q15
        if profile_type == "high_performer":
            q9_base = [0.05, 0.30, 0.40, 0.25]   # Never, Occasionally, Regularly, Daily
        elif profile_type == "at_risk":
            q9_base = [0.45, 0.35, 0.15, 0.05]
        else:
            q9_base = [0.20, 0.50, 0.22, 0.08]
        if grade == 12:
            q9_weights = [max(0, q9_base[0] - 0.03), max(0, q9_base[1] - 0.02),
                          q9_base[2] + 0.03, q9_base[3] + 0.02]
        else:
            q9_weights = q9_base
        q9 = random.choices(self.AI_TOOL_USAGE, weights=q9_weights)[0]

        # Q8 — derives from Q4 (loose correlation)
        q8_style_weights = {
            "Video":          [0.20, 0.50, 0.20, 0.10],
            "Solved Example": [0.20, 0.15, 0.50, 0.15],
            "Textbook":       [0.15, 0.10, 0.15, 0.60],
            "1-on-1 Chat":    [0.40, 0.25, 0.20, 0.15],
        }
        q8 = random.choices(
            self.LEARNING_STYLES,
            weights=q8_style_weights.get(profile_data["pedagogical_pref"], [0.25, 0.25, 0.25, 0.25])
        )[0]

        # Q10 — derives from profile + Q9 (AI trust score 1-5)
        if profile_type == "high_performer":
            q10_base = [0.05, 0.10, 0.20, 0.40, 0.25]
        elif profile_type == "at_risk":
            q10_base = [0.10, 0.35, 0.35, 0.15, 0.05]
        else:
            q10_base = [0.05, 0.15, 0.40, 0.30, 0.10]
        q9_factor = {
            "Daily":        [0.3, 0.5, 0.7, 1.3, 1.5],
            "Regularly":    [0.5, 0.8, 1.0, 1.2, 1.3],
            "Never":        [1.5, 1.3, 1.0, 0.7, 0.4],
            "Occasionally": [1.0, 1.0, 1.0, 1.0, 1.0],
        }[q9]
        q10_raw = [b * f for b, f in zip(q10_base, q9_factor)]
        q10_total = sum(q10_raw)
        q10_norm = [w / q10_total for w in q10_raw]
        q10 = random.choices([1, 2, 3, 4, 5], weights=q10_norm)[0]

        # Q11 — dashboard motivation (profile only)
        if profile_type == "high_performer":
            q11_w = [0.70, 0.10, 0.20]
        elif profile_type == "at_risk":
            q11_w = [0.60, 0.10, 0.30]
        else:
            q11_w = [0.65, 0.10, 0.25]
        q11 = random.choices(self.DASHBOARD_MOTIVATION, weights=q11_w)[0]

        # Q12 — teacher visibility (profile only)
        if profile_type == "high_performer":
            q12_w = [0.50, 0.15, 0.35]   # Yes, No, Only if I choose
        elif profile_type == "at_risk":
            q12_w = [0.25, 0.40, 0.35]
        else:
            q12_w = [0.30, 0.25, 0.45]
        q12 = random.choices(self.TEACHER_VISIBILITY, weights=q12_w)[0]

        # Q13 — data privacy preference (profile only)
        if profile_type == "high_performer":
            q13_w = [0.25, 0.35, 0.40]   # Device only, School servers, Don't mind
        elif profile_type == "at_risk":
            q13_w = [0.55, 0.30, 0.15]
        else:
            q13_w = [0.35, 0.40, 0.25]
        q13 = random.choices(self.DATA_PRIVACY_PREF, weights=q13_w)[0]

        # Q14 — hardest subject (profile + grade)
        if profile_type == "at_risk":
            q14_base = [0.35, 0.30, 0.15, 0.12, 0.08]
        elif profile_type == "high_performer":
            q14_base = [0.28, 0.22, 0.18, 0.15, 0.17]
        else:
            q14_base = [0.30, 0.25, 0.20, 0.15, 0.10]
        grade_factor = [1.0, 1.0, 1.3, 1.3, 0.5] if grade == 10 else [1.0, 1.0, 0.8, 0.8, 1.8]
        q14_raw = [b * f for b, f in zip(q14_base, grade_factor)]
        q14_total = sum(q14_raw)
        q14_norm = [w / q14_total for w in q14_raw]
        q14 = random.choices(self.HARDEST_SUBJECTS, weights=q14_norm)[0]

        # Q15 — help-seeking behaviour (profile + Q9)
        if profile_type == "high_performer":
            q15_base = [0.25, 0.15, 0.30, 0.00, 0.30]
        elif profile_type == "at_risk":
            q15_base = [0.35, 0.20, 0.07, 0.35, 0.03]
        else:
            q15_base = [0.40, 0.25, 0.20, 0.05, 0.10]
        q15_factor = {
            "Regularly": [0.8, 0.9, 1.0, 0.4, 2.5],
            "Daily":     [0.8, 0.9, 1.0, 0.4, 2.5],
            "Never":     [1.3, 1.2, 1.1, 1.3, 0.1],
            "Occasionally": [1.0, 1.0, 1.0, 1.0, 1.0],
        }[q9]
        q15_raw = [b * f for b, f in zip(q15_base, q15_factor)]
        q15_total = sum(q15_raw)
        if q15_total == 0:
            q15_raw = [0.2, 0.2, 0.2, 0.2, 0.2]
            q15_total = 1.0
        q15_norm = [w / q15_total for w in q15_raw]
        q15 = random.choices(self.HELP_SEEKING, weights=q15_norm)[0]

        # Compile complete record
        record = {
            "Student_ID": f"STU_{student_id:03d}",
            "Name": self.generate_name(),
            "Grade": grade,
            "Institute": institute,
            "Location": "Karad, Maharashtra",
            "Q1_Confidence_Score": profile_data["confidence"],
            "Q2_Phone_Checks": profile_data["phone_checks"],
            "Q3_Study_Inhibitor": profile_data["inhibitor"],
            "Q4_Pedagogical_Preference": profile_data["pedagogical_pref"],
            "Q5_Goal_Orientation": goal,
            "Q6_Persistence_Minutes": profile_data["persistence"],
            "Q7_Discussion_Frequency": profile_data["discussion"],
            "Q8_Learning_Style": q8,
            "Q9_AI_Tool_Usage": q9,
            "Q10_AI_Trust_Score": q10,
            "Q11_Dashboard_Motivation": q11,
            "Q12_Teacher_Visibility": q12,
            "Q13_Data_Privacy_Pref": q13,
            "Q14_Hardest_Subject": q14,
            "Q15_Help_Seeking": q15,
            "Profile_Type": profile_type  # Hidden metadata for validation
        }
        
        return record
    
    def generate_dataset(self) -> pd.DataFrame:
        """
        Generate the complete synthetic student dataset.
        
        Returns:
            Pandas DataFrame with all student records
        """
        print("=" * 70)
        print("Student Data Generation Strategy - Adaptive Scaffolding System")
        print("=" * 70)
        print(f"\nGenerating {self.num_students} student records...")
        print(f"  - 10th Grade: {self.num_10th} students")
        print(f"  - 12th Grade: {self.num_12th} students")
        print(f"\nLocation: Karad, Maharashtra")
        print(f"Generation Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("\n" + "-" * 70)
        
        records = []
        
        # Generate 10th grade students
        for i in range(1, self.num_10th + 1):
            record = self.generate_student_record(i, grade=10)
            records.append(record)
        
        # Generate 12th grade students
        for i in range(self.num_10th + 1, self.num_students + 1):
            record = self.generate_student_record(i, grade=12)
            records.append(record)
        
        df = pd.DataFrame(records)
        
        print(f"\n[OK] Successfully generated {len(df)} student records")
        print("\nData Distribution Summary:")
        print("-" * 70)
        print(f"\nGrade Distribution:")
        print(df['Grade'].value_counts().to_string())
        print(f"\nProfile Type Distribution:")
        print(df['Profile_Type'].value_counts().to_string())
        print(f"\nGoal Orientation (10th Grade):")
        print(df[df['Grade'] == 10]['Q5_Goal_Orientation'].value_counts().to_string())
        print(f"\nGoal Orientation (12th Grade):")
        print(df[df['Grade'] == 12]['Q5_Goal_Orientation'].value_counts().to_string())
        print(f"\nAI Tool Usage (Q9):")
        print(df['Q9_AI_Tool_Usage'].value_counts().to_string())
        print(f"\nHardest Subject (Q14):")
        print(df['Q14_Hardest_Subject'].value_counts().to_string())

        return df
    
    def save_to_csv(self, df: pd.DataFrame, filename: str = "student_data.csv", 
                    include_metadata: bool = False):
        """
        Save the generated dataset to a CSV file.
        
        Args:
            df: DataFrame to save
            filename: Output filename
            include_metadata: Whether to include Profile_Type column (for validation)
        """
        if not include_metadata:
            # Remove metadata column for production use
            df_output = df.drop(columns=['Profile_Type'])
        else:
            df_output = df
        
        df_output.to_csv(filename, index=False)
        print(f"\n[OK] Data saved to: {filename}")
        print(f"  Total records: {len(df_output)}")
        print(f"  Columns: {len(df_output.columns)}")
        print("=" * 70)
    
    def generate_statistics_report(self, df: pd.DataFrame) -> str:
        """
        Generate a detailed statistics report for validation.
        
        Args:
            df: DataFrame to analyze
            
        Returns:
            Formatted statistics report
        """
        report = []
        report.append("\n" + "=" * 70)
        report.append("DETAILED STATISTICS REPORT")
        report.append("=" * 70)
        
        # Confidence Score Statistics
        report.append("\n1. Q1 - Confidence Score Distribution:")
        report.append("-" * 70)
        for profile in ["high_performer", "at_risk", "average"]:
            subset = df[df['Profile_Type'] == profile]['Q1_Confidence_Score']
            report.append(f"\n{profile.replace('_', ' ').title()}:")
            report.append(f"  Mean: {subset.mean():.2f}")
            report.append(f"  Median: {subset.median():.2f}")
            report.append(f"  Range: {subset.min()} - {subset.max()}")
        
        # Phone Checks Distribution
        report.append("\n\n2. Q2 - Phone Checks Distribution by Profile:")
        report.append("-" * 70)
        for profile in ["high_performer", "at_risk", "average"]:
            subset = df[df['Profile_Type'] == profile]
            report.append(f"\n{profile.replace('_', ' ').title()}:")
            counts = subset['Q2_Phone_Checks'].value_counts()
            for check, count in counts.items():
                pct = (count / len(subset)) * 100
                report.append(f"  {check}: {count} ({pct:.1f}%)")
        
        # Persistence Statistics
        report.append("\n\n3. Q6 - Persistence (Minutes) Distribution:")
        report.append("-" * 70)
        for profile in ["high_performer", "at_risk", "average"]:
            subset = df[df['Profile_Type'] == profile]['Q6_Persistence_Minutes']
            report.append(f"\n{profile.replace('_', ' ').title()}:")
            report.append(f"  Mean: {subset.mean():.2f} minutes")
            report.append(f"  Median: {subset.median():.2f} minutes")
            report.append(f"  Range: {subset.min()} - {subset.max()} minutes")
        
        # Institute Distribution
        report.append("\n\n4. Institute Distribution:")
        report.append("-" * 70)
        report.append("\n10th Grade:")
        inst_10 = df[df['Grade'] == 10]['Institute'].value_counts()
        for inst, count in inst_10.items():
            report.append(f"  {inst}: {count}")
        
        report.append("\n12th Grade:")
        inst_12 = df[df['Grade'] == 12]['Institute'].value_counts()
        for inst, count in inst_12.items():
            report.append(f"  {inst}: {count}")

        # Q9 AI Tool Usage
        report.append("\n\n5. Q9 - AI Tool Usage by Profile:")
        report.append("-" * 70)
        for profile in ["high_performer", "at_risk", "average"]:
            subset = df[df['Profile_Type'] == profile]
            report.append(f"\n{profile.replace('_', ' ').title()}:")
            for val, count in subset['Q9_AI_Tool_Usage'].value_counts().items():
                report.append(f"  {val}: {count} ({count/len(subset)*100:.1f}%)")
        report.append("\nQ9 - AI Tool Usage by Grade:")
        for grade in [10, 12]:
            subset = df[df['Grade'] == grade]
            report.append(f"\nGrade {grade}:")
            for val, count in subset['Q9_AI_Tool_Usage'].value_counts().items():
                report.append(f"  {val}: {count} ({count/len(subset)*100:.1f}%)")

        # Q10 AI Trust Score
        report.append("\n\n6. Q10 - AI Trust Score by Profile:")
        report.append("-" * 70)
        for profile in ["high_performer", "at_risk", "average"]:
            subset = df[df['Profile_Type'] == profile]['Q10_AI_Trust_Score']
            report.append(f"\n{profile.replace('_', ' ').title()}:")
            report.append(f"  Mean: {subset.mean():.2f}")
            report.append(f"  Median: {subset.median():.2f}")
            report.append(f"  Range: {subset.min()} - {subset.max()}")

        # Q14 Hardest Subject
        report.append("\n\n7. Q14 - Hardest Subject by Profile:")
        report.append("-" * 70)
        for profile in ["high_performer", "at_risk", "average"]:
            subset = df[df['Profile_Type'] == profile]
            report.append(f"\n{profile.replace('_', ' ').title()}:")
            for val, count in subset['Q14_Hardest_Subject'].value_counts().items():
                report.append(f"  {val}: {count} ({count/len(subset)*100:.1f}%)")
        report.append("\nQ14 - Hardest Subject by Grade:")
        for grade in [10, 12]:
            subset = df[df['Grade'] == grade]
            report.append(f"\nGrade {grade}:")
            for val, count in subset['Q14_Hardest_Subject'].value_counts().items():
                report.append(f"  {val}: {count} ({count/len(subset)*100:.1f}%)")

        # Q8 Learning Style and Q15 Help Seeking
        report.append("\n\n8. Q8 & Q15 - Learning Style and Help Seeking by Profile:")
        report.append("-" * 70)
        for profile in ["high_performer", "at_risk", "average"]:
            subset = df[df['Profile_Type'] == profile]
            report.append(f"\n{profile.replace('_', ' ').title()} — Learning Style (Q8):")
            for val, count in subset['Q8_Learning_Style'].value_counts().items():
                report.append(f"  {val}: {count} ({count/len(subset)*100:.1f}%)")
            report.append(f"{profile.replace('_', ' ').title()} — Help Seeking (Q15):")
            for val, count in subset['Q15_Help_Seeking'].value_counts().items():
                report.append(f"  {val}: {count} ({count/len(subset)*100:.1f}%)")

        report.append("\n" + "=" * 70)

        return "\n".join(report)


def main():
    """
    Main execution function.
    """
    # Configuration
    NUM_STUDENTS = 1000  # Total number of students to generate
    GRADE_10_RATIO = 0.5  # 50% 10th grade, 50% 12th grade
    OUTPUT_FILE = "student_data.csv"
    OUTPUT_FILE_WITH_METADATA = "student_data_with_metadata.csv"
    
    # Initialize generator
    generator = StudentDataGenerator(
        num_students=NUM_STUDENTS,
        grade_10_ratio=GRADE_10_RATIO
    )
    
    # Generate dataset
    df = generator.generate_dataset()
    
    # Save to CSV (without metadata for production)
    generator.save_to_csv(df, filename=OUTPUT_FILE, include_metadata=False)
    
    # Save with metadata for validation/analysis
    generator.save_to_csv(df, filename=OUTPUT_FILE_WITH_METADATA, include_metadata=True)
    
    # Generate and print statistics report
    report = generator.generate_statistics_report(df)
    print(report)
    
    # Save report to file
    with open("generation_report.txt", "w", encoding="utf-8") as f:
        f.write(report)
    print(f"\n[OK] Statistics report saved to: generation_report.txt")


if __name__ == "__main__":
    main()
