import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

# Set seed for reproducibility
np.random.seed(42)
random.seed(42)

print("Expanding screenings data from 60 to 560 rows...")

# =============================================================================
# CONFIGURATION
# =============================================================================
EXISTING_SCREENINGS = 60  # Keep first 60 unchanged
NEW_SCREENINGS = 500      # Add 500 more
TOTAL_SCREENINGS = 560

START_DATE = datetime(2023, 1, 1)
END_DATE = datetime(2025, 3, 31)

# Target: 75% of new screenings need follow-up (abnormal or cancer)
FOLLOWUP_RATE = 0.75

# =============================================================================
# LOAD EXISTING SCREENINGS
# =============================================================================

try:
    existing_df = pd.read_csv('seeds/raw_screenings.csv')
    print(f"\n✅ Loaded {len(existing_df)} existing screenings from seeds/raw_screenings.csv")
    
    # Get max screening_id to continue numbering
    max_screening_num = int(existing_df['screening_id'].str.replace('SCR', '').max())
    print(f"   Last screening ID: SCR{str(max_screening_num).zfill(6)}")
    
except FileNotFoundError:
    print("\n❌ Error: seeds/raw_screenings.csv not found!")
    print("   Make sure you're running this from the project root directory.")
    exit(1)

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def calculate_followup_probability(age_group, gender, screening_type, days_to_result, day_of_week):
    """
    Calculate probability of follow-up completion based on features.
    Based on healthcare research patterns.
    """
    prob = 0.75  # Base completion rate
    
    # Age effect: Older patients more compliant
    age_effects = {
        'Under 40': -0.15,
        '40-49': -0.05,
        '50-64': 0.05,
        '65+': 0.10
    }
    # Extract age from screening context (approximate)
    prob += age_effects.get(age_group, 0)
    
    # Gender effect: Women slightly more compliant
    if gender == 'F':
        prob += 0.05
    elif gender == 'M':
        prob -= 0.03
    
    # Screening type effect
    screening_effects = {
        'Mammogram': 0.08,
        'Colonoscopy': 0.05,
        'Prostate Screening': 0.00,
        'Cervical Screening': 0.03
    }
    prob += screening_effects.get(screening_type, 0)
    
    # Days to result effect
    if days_to_result <= 7:
        prob += 0.15
    elif days_to_result <= 14:
        prob += 0.05
    elif days_to_result > 21:
        prob -= 0.10
    
    # Day of week effect
    if day_of_week in ['Monday', 'Tuesday', 'Wednesday', 'Thursday']:
        prob += 0.05
    elif day_of_week == 'Friday':
        prob += 0.00
    else:  # Weekend
        prob -= 0.08
    
    # Keep probability within bounds
    prob = max(0.2, min(0.95, prob))
    
    return prob

def assign_screening_type_by_demographics(age, gender):
    """Assign realistic screening type based on age/gender"""
    if gender == 'F' and age >= 40:
        return np.random.choice(
            ['Mammogram', 'Colonoscopy', 'Cervical Screening'],
            p=[0.60, 0.30, 0.10]
        )
    elif gender == 'M' and age >= 50:
        return np.random.choice(
            ['Colonoscopy', 'Prostate Screening'],
            p=[0.65, 0.35]
        )
    elif age >= 50:
        return 'Colonoscopy'
    else:
        return np.random.choice(
            ['Cervical Screening', 'General Health Screening'],
            p=[0.70, 0.30]
        )

# =============================================================================
# GENERATE NEW SCREENINGS
# =============================================================================

print(f"\n📊 Generating {NEW_SCREENINGS} new screenings...")

new_screenings = []

# Use existing member_ids (MEM00001-MEM00100)
member_ids = [f'MEM{str(i).zfill(5)}' for i in range(1, 101)]

# Use existing employer_ids (EMP001-EMP010)
employer_ids = [f'EMP{str(i).zfill(3)}' for i in range(1, 11)]

# Use existing provider_ids (PROV0001-PROV0010)
provider_ids = [f'PROV{str(i).zfill(4)}' for i in range(1, 11)]

# Generate age groups for members (approximate based on member_id pattern)
# We'll simulate ages for the purposes of screening assignment
member_ages = {}
for member_id in member_ids:
    member_ages[member_id] = {
        'age': np.random.choice([35, 42, 48, 55, 62, 70], p=[0.10, 0.20, 0.20, 0.25, 0.15, 0.10]),
        'gender': np.random.choice(['M', 'F', 'Other'], p=[0.48, 0.50, 0.02])
    }

for i in range(NEW_SCREENINGS):
    screening_id = f'SCR{str(max_screening_num + i + 1).zfill(6)}'
    member_id = np.random.choice(member_ids)
    employer_id = np.random.choice(employer_ids)
    provider_id = np.random.choice(provider_ids)
    
    # Get member demographics
    age = member_ages[member_id]['age']
    gender = member_ages[member_id]['gender']
    age_group = (
        'Under 40' if age < 40 else
        '40-49' if age < 50 else
        '50-64' if age < 65 else
        '65+'
    )
    
    # Assign screening type based on demographics
    screening_type = assign_screening_type_by_demographics(age, gender)
    
    # Generate screening date
    screening_date = START_DATE + timedelta(days=np.random.randint(0, (END_DATE - START_DATE).days))
    
    # Days to result (7-21 days typical)
    days_to_result = int(np.random.choice(
        np.concatenate([
            np.random.randint(7, 15, 60),   # 60% fast
            np.random.randint(15, 22, 30),  # 30% moderate
            np.random.randint(22, 45, 10)   # 10% slow
        ])
    ))
    
    result_date = screening_date + timedelta(days=days_to_result)
    day_of_week = result_date.strftime('%A')
    
    # Result distribution: 75% need follow-up (abnormal or cancer)
    needs_followup = np.random.random() < FOLLOWUP_RATE
    
    if needs_followup:
        # 90% abnormal-benign, 10% cancer detected
        result = np.random.choice(
            ['Abnormal - Benign', 'Cancer Detected'],
            p=[0.90, 0.10]
        )
        follow_up_needed = True
        
        # Calculate follow-up completion probability
        completion_prob = calculate_followup_probability(
            age_group, gender, screening_type, days_to_result, day_of_week
        )
        follow_up_completed = np.random.random() < completion_prob
    else:
        result = 'Normal'
        follow_up_needed = False
        follow_up_completed = None
    
    # Cost varies by screening type
    cost_ranges = {
        'Mammogram': (400, 500),
        'Colonoscopy': (1000, 1400),
        'Prostate Screening': (250, 350),
        'Cervical Screening': (200, 300),
        'General Health Screening': (150, 250)
    }
    cost_range = cost_ranges.get(screening_type, (200, 500))
    cost = np.random.randint(cost_range[0], cost_range[1])
    
    new_screenings.append({
        'screening_id': screening_id,
        'member_id': member_id,
        'employer_id': employer_id,
        'provider_id': provider_id,
        'screening_type': screening_type,
        'screening_date': screening_date.strftime('%Y-%m-%d'),
        'result': result,
        'result_date': result_date.strftime('%Y-%m-%d'),
        'follow_up_needed': follow_up_needed,
        'follow_up_completed': follow_up_completed,
        'cost': cost
    })

new_df = pd.DataFrame(new_screenings)

# =============================================================================
# COMBINE EXISTING + NEW SCREENINGS
# =============================================================================

# Ensure column order matches
column_order = existing_df.columns.tolist()
new_df = new_df[column_order]

# Combine
expanded_df = pd.concat([existing_df, new_df], ignore_index=True)

print(f"\n✅ Combined datasets:")
print(f"   Existing screenings: {len(existing_df)}")
print(f"   New screenings:      {len(new_df)}")
print(f"   Total screenings:    {len(expanded_df)}")

# =============================================================================
# SAVE EXPANDED FILE
# =============================================================================

# Backup original file
import shutil
shutil.copy('seeds/raw_screenings.csv', 'seeds/raw_screenings_backup.csv')
print(f"\n💾 Backed up original to: seeds/raw_screenings_backup.csv")

# Save expanded file
expanded_df.to_csv('seeds/raw_screenings.csv', index=False)
print(f"✅ Saved expanded file to: seeds/raw_screenings.csv")

# =============================================================================
# SUMMARY STATISTICS
# =============================================================================

print("\n" + "="*60)
print("SCREENING DATA EXPANSION COMPLETE!")
print("="*60)

print(f"\n📊 Result Distribution (All {len(expanded_df)} screenings):")
result_counts = expanded_df['result'].value_counts()
for result, count in result_counts.items():
    pct = count / len(expanded_df) * 100
    print(f"  {result}: {count} ({pct:.1f}%)")

print(f"\n📊 Follow-Up Analysis (New {len(new_df)} screenings only):")
new_followup_needed = new_df['follow_up_needed'].sum()
new_followup_completed = new_df[new_df['follow_up_needed'] == True]['follow_up_completed'].sum()
print(f"  Screenings needing follow-up:  {new_followup_needed} ({new_followup_needed/len(new_df)*100:.1f}%)")
print(f"  Follow-ups completed:          {new_followup_completed} ({new_followup_completed/new_followup_needed*100:.1f}%)")

print(f"\n📊 Overall Follow-Up Analysis (All {len(expanded_df)} screenings):")
total_followup_needed = expanded_df['follow_up_needed'].sum()
total_followup_completed = expanded_df[expanded_df['follow_up_needed'] == True]['follow_up_completed'].sum()
print(f"  Screenings needing follow-up:  {total_followup_needed}")
print(f"  Follow-ups completed:          {total_followup_completed}")
print(f"  Follow-up completion rate:     {total_followup_completed/total_followup_needed*100:.1f}%")

print(f"\n📊 Screening Type Distribution:")
print(expanded_df['screening_type'].value_counts())

print("\n" + "="*60)
print("NEXT STEPS:")
print("  1. Run: dbt seed --select raw_screenings --full-refresh")
print("  2. Run: dbt run --select staging core marts")
print("  3. Verify expanded data in BigQuery")
print("="*60)