"""
Data Analysis and Validation Script
====================================

This script provides additional analysis and validation tools for the generated student data.
Use this to verify data quality and explore patterns before ML model training.
"""

import pandas as pd
import numpy as np
from collections import Counter


def load_data(filename="student_data_with_metadata.csv"):
    """Load the generated student data."""
    df = pd.read_csv(filename)
    print(f"Loaded {len(df)} student records from {filename}")
    return df


def validate_correlations(df):
    """
    Validate that the correlation logic is working correctly.
    """
    print("\n" + "=" * 70)
    print("CORRELATION VALIDATION REPORT")
    print("=" * 70)
    
    # Validate High-Performer Profile
    high_performers = df[df['Profile_Type'] == 'high_performer']
    print(f"\n1. High-Performer Profile Validation ({len(high_performers)} students):")
    print("-" * 70)
    
    # Check confidence >= 8
    conf_check = (high_performers['Q1_Confidence_Score'] >= 8).all()
    print(f"   Confidence >= 8: {'PASS' if conf_check else 'FAIL'}")
    
    # Check low distractions (1-3 or 4-6)
    low_dist = high_performers['Q2_Phone_Checks'].isin(['1-3', '4-6']).sum()
    low_dist_pct = (low_dist / len(high_performers)) * 100
    print(f"   Low distractions (1-3 or 4-6): {low_dist_pct:.1f}% (Expected: ~100%)")
    
    # Check high persistence
    high_pers = (high_performers['Q6_Persistence_Minutes'] >= 20).sum()
    high_pers_pct = (high_pers / len(high_performers)) * 100
    print(f"   High persistence (>= 20 min): {high_pers_pct:.1f}% (Expected: ~100%)")
    
    # Validate At-Risk Profile
    at_risk = df[df['Profile_Type'] == 'at_risk']
    print(f"\n2. At-Risk Profile Validation ({len(at_risk)} students):")
    print("-" * 70)
    
    # Check confidence <= 3
    conf_check = (at_risk['Q1_Confidence_Score'] <= 3).all()
    print(f"   Confidence <= 3: {'PASS' if conf_check else 'FAIL'}")
    
    # Check high distractions
    high_dist = at_risk['Q2_Phone_Checks'].isin(['4-6', '7+']).sum()
    high_dist_pct = (high_dist / len(at_risk)) * 100
    print(f"   High distractions (4-6 or 7+): {high_dist_pct:.1f}% (Expected: ~100%)")
    
    # Check low persistence
    low_pers = (at_risk['Q6_Persistence_Minutes'] <= 10).sum()
    low_pers_pct = (low_pers / len(at_risk)) * 100
    print(f"   Low persistence (<= 10 min): {low_pers_pct:.1f}% (Expected: ~100%)")
    
    # Validate Grade-Specific Goal Orientations
    print(f"\n3. Grade-Specific Goal Orientation Validation:")
    print("-" * 70)
    
    # 10th Grade
    grade_10 = df[df['Grade'] == 10]
    boards_10 = (grade_10['Q5_Goal_Orientation'] == '90%+ Boards').sum()
    boards_10_pct = (boards_10 / len(grade_10)) * 100
    print(f"   10th Grade - '90%+ Boards': {boards_10_pct:.1f}% (Expected: ~85%)")
    
    # 12th Grade
    grade_12 = df[df['Grade'] == 12]
    jee_12 = (grade_12['Q5_Goal_Orientation'] == 'JEE/NEET/CET').sum()
    jee_12_pct = (jee_12 / len(grade_12)) * 100
    print(f"   12th Grade - 'JEE/NEET/CET': {jee_12_pct:.1f}% (Expected: ~75%)")

    # Q8 <-> Q4 correlation
    print(f"\n4. Q8-Q4 Learning Style / Pedagogical Preference Correlation:")
    print("-" * 70)
    video_pref = df[df['Q4_Pedagogical_Preference'] == 'Video']
    auditory_pct = (video_pref['Q8_Learning_Style'] == 'Auditory').sum() / len(video_pref) * 100
    print(f"   Video->Q4: Auditory learning style: {auditory_pct:.1f}% (Expected: >40%)")
    text_pref = df[df['Q4_Pedagogical_Preference'] == 'Textbook']
    rw_pct = (text_pref['Q8_Learning_Style'] == 'Read-Write').sum() / len(text_pref) * 100
    print(f"   Textbook->Q4: Read-Write learning style: {rw_pct:.1f}% (Expected: >50%)")

    # Q10 <-> Q9 correlation
    print(f"\n5. Q10-Q9 AI Trust Score / AI Usage Correlation:")
    print("-" * 70)
    daily_users = df[df['Q9_AI_Tool_Usage'] == 'Daily']
    never_users = df[df['Q9_AI_Tool_Usage'] == 'Never']
    daily_trust = daily_users['Q10_AI_Trust_Score'].mean()
    never_trust = never_users['Q10_AI_Trust_Score'].mean()
    print(f"   Daily AI users mean trust: {daily_trust:.2f} (Expected: >3.5)")
    print(f"   Never AI users mean trust: {never_trust:.2f} (Expected: <3.0)")
    print(f"   Daily trust > Never trust: {'PASS' if daily_trust > never_trust else 'FAIL'}")

    # Q15 <-> Q9 correlation
    print(f"\n6. Q15-Q9 Help Seeking / AI Usage Correlation:")
    print("-" * 70)
    ai_users = df[df['Q9_AI_Tool_Usage'].isin(['Regularly', 'Daily'])]
    non_ai = df[df['Q9_AI_Tool_Usage'] == 'Never']
    ai_chatgpt_pct = (ai_users['Q15_Help_Seeking'] == 'Use ChatGPT/AI').sum() / len(ai_users) * 100
    non_chatgpt_pct = (non_ai['Q15_Help_Seeking'] == 'Use ChatGPT/AI').sum() / len(non_ai) * 100
    print(f"   AI users choosing ChatGPT/AI for help: {ai_chatgpt_pct:.1f}% (Expected: >40%)")
    print(f"   Non-AI users choosing ChatGPT/AI: {non_chatgpt_pct:.1f}% (Expected: <10%)")

    print("\n" + "=" * 70)


def analyze_by_profile(df):
    """
    Detailed analysis by student profile type.
    """
    print("\n" + "=" * 70)
    print("PROFILE-BASED ANALYSIS")
    print("=" * 70)
    
    for profile in ['high_performer', 'at_risk', 'average']:
        subset = df[df['Profile_Type'] == profile]
        
        print(f"\n{profile.replace('_', ' ').title()} ({len(subset)} students):")
        print("-" * 70)
        
        # Confidence statistics
        print(f"Confidence Score:")
        print(f"  Mean: {subset['Q1_Confidence_Score'].mean():.2f}")
        print(f"  Std Dev: {subset['Q1_Confidence_Score'].std():.2f}")
        print(f"  Range: {subset['Q1_Confidence_Score'].min()} - {subset['Q1_Confidence_Score'].max()}")
        
        # Persistence statistics
        print(f"\nPersistence (Minutes):")
        print(f"  Mean: {subset['Q6_Persistence_Minutes'].mean():.2f}")
        print(f"  Std Dev: {subset['Q6_Persistence_Minutes'].std():.2f}")
        print(f"  Range: {subset['Q6_Persistence_Minutes'].min()} - {subset['Q6_Persistence_Minutes'].max()}")
        
        # Phone checks distribution
        print(f"\nPhone Checks Distribution:")
        phone_dist = subset['Q2_Phone_Checks'].value_counts()
        for check, count in phone_dist.items():
            pct = (count / len(subset)) * 100
            print(f"  {check}: {count} ({pct:.1f}%)")
        
        # Top study inhibitors
        print(f"\nTop Study Inhibitors:")
        inhibitors = subset['Q3_Study_Inhibitor'].value_counts().head(3)
        for inhibitor, count in inhibitors.items():
            pct = (count / len(subset)) * 100
            print(f"  {inhibitor}: {count} ({pct:.1f}%)")
        
        # Pedagogical preferences
        print(f"\nPedagogical Preferences:")
        prefs = subset['Q4_Pedagogical_Preference'].value_counts()
        for pref, count in prefs.items():
            pct = (count / len(subset)) * 100
            print(f"  {pref}: {count} ({pct:.1f}%)")

        # New Q8-Q15 distributions
        for col, label in [
            ("Q8_Learning_Style", "Learning Style (VARK)"),
            ("Q9_AI_Tool_Usage", "AI Tool Usage"),
            ("Q11_Dashboard_Motivation", "Dashboard Motivation"),
            ("Q12_Teacher_Visibility", "Teacher Visibility Comfort"),
            ("Q13_Data_Privacy_Pref", "Data Privacy Preference"),
            ("Q14_Hardest_Subject", "Hardest Subject"),
            ("Q15_Help_Seeking", "Help Seeking Behaviour"),
        ]:
            print(f"\n{label}:")
            for val, count in subset[col].value_counts().items():
                pct = (count / len(subset)) * 100
                print(f"  {val}: {count} ({pct:.1f}%)")

        print(f"\nAI Trust Score (Q10):")
        print(f"  Mean: {subset['Q10_AI_Trust_Score'].mean():.2f}")
        print(f"  Median: {subset['Q10_AI_Trust_Score'].median():.2f}")
        print(f"  Range: {subset['Q10_AI_Trust_Score'].min()} - {subset['Q10_AI_Trust_Score'].max()}")


def analyze_by_grade(df):
    """
    Detailed analysis by grade level.
    """
    print("\n" + "=" * 70)
    print("GRADE-BASED ANALYSIS")
    print("=" * 70)
    
    for grade in [10, 12]:
        subset = df[df['Grade'] == grade]
        
        print(f"\nGrade {grade} ({len(subset)} students):")
        print("-" * 70)
        
        # Institute distribution
        print(f"Institute Distribution:")
        institutes = subset['Institute'].value_counts()
        for inst, count in institutes.items():
            pct = (count / len(subset)) * 100
            print(f"  {inst}: {count} ({pct:.1f}%)")
        
        # Goal orientation
        print(f"\nGoal Orientation:")
        goals = subset['Q5_Goal_Orientation'].value_counts()
        for goal, count in goals.items():
            pct = (count / len(subset)) * 100
            print(f"  {goal}: {count} ({pct:.1f}%)")
        
        # Profile distribution
        print(f"\nProfile Distribution:")
        profiles = subset['Profile_Type'].value_counts()
        for profile, count in profiles.items():
            pct = (count / len(subset)) * 100
            print(f"  {profile}: {count} ({pct:.1f}%)")
        
        # Average confidence by profile
        print(f"\nAverage Confidence by Profile:")
        for profile in ['high_performer', 'at_risk', 'average']:
            profile_subset = subset[subset['Profile_Type'] == profile]
            if len(profile_subset) > 0:
                avg_conf = profile_subset['Q1_Confidence_Score'].mean()
                print(f"  {profile}: {avg_conf:.2f}")

        # Q9 AI usage by grade
        print(f"\nAI Tool Usage (Q9):")
        for val, count in subset['Q9_AI_Tool_Usage'].value_counts().items():
            pct = (count / len(subset)) * 100
            print(f"  {val}: {count} ({pct:.1f}%)")

        # Q14 hardest subject by grade
        print(f"\nHardest Subject (Q14):")
        for val, count in subset['Q14_Hardest_Subject'].value_counts().items():
            pct = (count / len(subset)) * 100
            print(f"  {val}: {count} ({pct:.1f}%)")


def find_interesting_patterns(df):
    """
    Find interesting patterns and outliers in the data.
    """
    print("\n" + "=" * 70)
    print("INTERESTING PATTERNS & INSIGHTS")
    print("=" * 70)
    
    # Students with high confidence but high distractions (unusual)
    unusual_1 = df[(df['Q1_Confidence_Score'] >= 8) & (df['Q2_Phone_Checks'].isin(['4-6', '7+']))]
    print(f"\n1. High Confidence + High Distractions (Unusual Pattern):")
    print(f"   Count: {len(unusual_1)} students ({(len(unusual_1)/len(df)*100):.1f}%)")
    
    # Students with low confidence but low distractions (potential for improvement)
    unusual_2 = df[(df['Q1_Confidence_Score'] <= 3) & (df['Q2_Phone_Checks'] == '1-3')]
    print(f"\n2. Low Confidence + Low Distractions (Improvement Potential):")
    print(f"   Count: {len(unusual_2)} students ({(len(unusual_2)/len(df)*100):.1f}%)")
    
    # Students who never discuss but have high confidence
    unusual_3 = df[(df['Q1_Confidence_Score'] >= 8) & (df['Q7_Discussion_Frequency'] == 'Never')]
    print(f"\n3. High Confidence + Never Discuss (Independent Learners):")
    print(f"   Count: {len(unusual_3)} students ({(len(unusual_3)/len(df)*100):.1f}%)")
    
    # Students with very high persistence (>40 mins)
    high_persist = df[df['Q6_Persistence_Minutes'] > 40]
    print(f"\n4. Very High Persistence (>40 minutes):")
    print(f"   Count: {len(high_persist)} students ({(len(high_persist)/len(df)*100):.1f}%)")
    print(f"   Average Confidence: {high_persist['Q1_Confidence_Score'].mean():.2f}")
    
    # Most common combinations
    print(f"\n5. Most Common Study Inhibitor by Profile:")
    for profile in ['high_performer', 'at_risk', 'average']:
        subset = df[df['Profile_Type'] == profile]
        top_inhibitor = subset['Q3_Study_Inhibitor'].mode()[0]
        count = (subset['Q3_Study_Inhibitor'] == top_inhibitor).sum()
        pct = (count / len(subset)) * 100
        print(f"   {profile}: {top_inhibitor} ({pct:.1f}%)")

    # New patterns for Q8-Q15
    at_risk_df = df[df['Profile_Type'] == 'at_risk']
    at_risk_gives_up = at_risk_df[at_risk_df['Q15_Help_Seeking'] == 'Give up']
    pct6 = len(at_risk_gives_up) / len(at_risk_df) * 100
    print(f"\n6. At-Risk Students Who Give Up (Q15):")
    print(f"   Count: {len(at_risk_gives_up)} of {len(at_risk_df)} at-risk students ({pct6:.1f}%) (Expected: ~35%)")

    hp_daily = df[(df['Profile_Type'] == 'high_performer') & (df['Q9_AI_Tool_Usage'] == 'Daily')]
    print(f"\n7. High Performers Using AI Daily (Q9):")
    print(f"   Count: {len(hp_daily)} students ({len(hp_daily)/len(df)*100:.1f}%)")
    print(f"   Mean AI Trust Score: {hp_daily['Q10_AI_Trust_Score'].mean():.2f} (Expected: >4.0)")

    private_at_risk = at_risk_df[at_risk_df['Q12_Teacher_Visibility'] == 'No I prefer privacy']
    pct8 = len(private_at_risk) / len(at_risk_df) * 100
    print(f"\n8. At-Risk Students Preferring Privacy from Teacher (Q12):")
    print(f"   Count: {len(private_at_risk)} ({pct8:.1f}% of at-risk) (Expected: ~40%)")
    print(f"   Note: These students are hardest to proactively support.")

    print("\n" + "=" * 70)


def export_summary_stats(df, filename="data_summary.txt"):
    """
    Export summary statistics to a text file.
    """
    with open(filename, 'w', encoding='utf-8') as f:
        f.write("STUDENT DATA SUMMARY STATISTICS\n")
        f.write("=" * 70 + "\n\n")
        
        f.write(f"Total Students: {len(df)}\n")
        f.write(f"10th Grade: {len(df[df['Grade'] == 10])}\n")
        f.write(f"12th Grade: {len(df[df['Grade'] == 12])}\n\n")
        
        f.write("Profile Distribution:\n")
        for profile, count in df['Profile_Type'].value_counts().items():
            pct = (count / len(df)) * 100
            f.write(f"  {profile}: {count} ({pct:.1f}%)\n")
        
        f.write("\nConfidence Score Statistics:\n")
        f.write(f"  Mean: {df['Q1_Confidence_Score'].mean():.2f}\n")
        f.write(f"  Median: {df['Q1_Confidence_Score'].median():.2f}\n")
        f.write(f"  Std Dev: {df['Q1_Confidence_Score'].std():.2f}\n")
        
        f.write("\nPersistence Statistics:\n")
        f.write(f"  Mean: {df['Q6_Persistence_Minutes'].mean():.2f} minutes\n")
        f.write(f"  Median: {df['Q6_Persistence_Minutes'].median():.2f} minutes\n")
        f.write(f"  Std Dev: {df['Q6_Persistence_Minutes'].std():.2f} minutes\n")

        f.write("\nAI Tool Usage Distribution (Q9):\n")
        for val, count in df['Q9_AI_Tool_Usage'].value_counts().items():
            f.write(f"  {val}: {count} ({count/len(df)*100:.1f}%)\n")

        f.write("\nAI Trust Score Statistics (Q10):\n")
        f.write(f"  Mean: {df['Q10_AI_Trust_Score'].mean():.2f}\n")
        f.write(f"  Median: {df['Q10_AI_Trust_Score'].median():.2f}\n")
        f.write(f"  Std Dev: {df['Q10_AI_Trust_Score'].std():.2f}\n")

        f.write("\nHardest Subject Distribution (Q14):\n")
        for val, count in df['Q14_Hardest_Subject'].value_counts().items():
            f.write(f"  {val}: {count} ({count/len(df)*100:.1f}%)\n")

        f.write("\nHelp Seeking Behaviour Distribution (Q15):\n")
        for val, count in df['Q15_Help_Seeking'].value_counts().items():
            f.write(f"  {val}: {count} ({count/len(df)*100:.1f}%)\n")

        f.write("\nLearning Style (VARK) Distribution (Q8):\n")
        for val, count in df['Q8_Learning_Style'].value_counts().items():
            f.write(f"  {val}: {count} ({count/len(df)*100:.1f}%)\n")

    print(f"\n[OK] Summary statistics exported to: {filename}")


def main():
    """
    Main analysis function.
    """
    print("=" * 70)
    print("STUDENT DATA ANALYSIS & VALIDATION")
    print("=" * 70)
    
    # Load data
    df = load_data()
    
    # Run validation
    validate_correlations(df)
    
    # Profile-based analysis
    analyze_by_profile(df)
    
    # Grade-based analysis
    analyze_by_grade(df)
    
    # Find interesting patterns
    find_interesting_patterns(df)
    
    # Export summary
    export_summary_stats(df)
    
    print("\n" + "=" * 70)
    print("ANALYSIS COMPLETE")
    print("=" * 70)


if __name__ == "__main__":
    main()
