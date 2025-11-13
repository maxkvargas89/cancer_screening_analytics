import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

# Set seed for reproducibility
np.random.seed(42)
random.seed(42)

# Configuration
NUM_EMPLOYERS = 10
NUM_MEMBERS = 1000
NUM_PROVIDERS = 50
START_DATE = datetime(2023, 1, 1)
END_DATE = datetime(2025, 11, 13)

print("Generating synthetic cancer screening data...")

# ============================================================================
# 1. EMPLOYERS
# ============================================================================
print("Generating employers...")

industries = ['Technology', 'Healthcare', 'Manufacturing', 'Retail', 'Finance', 
              'Education', 'Government', 'Hospitality', 'Construction', 'Legal']
              
employers = pd.DataFrame({
    'employer_id': [f'EMP{str(i).zfill(3)}' for i in range(1, NUM_EMPLOYERS + 1)],
    'employer_name': [f'{industries[i]} Corp {chr(65+i)}' for i in range(NUM_EMPLOYERS)],
    'industry': industries[:NUM_EMPLOYERS],
    'employee_count': np.random.choice([500, 1000, 2500, 5000, 10000], NUM_EMPLOYERS),
    'state': np.random.choice(['CA', 'NY', 'TX', 'FL', 'IL', 'WA', 'MA'], NUM_EMPLOYERS),
    'contract_start_date': pd.date_range(start='2022-01-01', periods=NUM_EMPLOYERS, freq='30D')
})

# ============================================================================
# 2. MEMBERS (Patients)
# ============================================================================
print("Generating members...")

# Age distribution: weighted toward screening-eligible ages (40-75)
ages = np.concatenate([
    np.random.randint(25, 40, 200),  # Younger adults
    np.random.randint(40, 65, 600),  # Primary screening age
    np.random.randint(65, 80, 200)   # Older adults
])

birth_dates = [datetime.now() - timedelta(days=age*365.25) for age in ages]

members = pd.DataFrame({
    'member_id': [f'MEM{str(i).zfill(5)}' for i in range(1, NUM_MEMBERS + 1)],
    'employer_id': np.random.choice(employers['employer_id'], NUM_MEMBERS),
    'first_name': [f'FirstName{i}' for i in range(1, NUM_MEMBERS + 1)],
    'last_name': [f'LastName{i}' for i in range(1, NUM_MEMBERS + 1)],
    'date_of_birth': birth_dates,
    'gender': np.random.choice(['M', 'F', 'Other'], NUM_MEMBERS, p=[0.48, 0.50, 0.02]),
    'state': np.random.choice(['CA', 'NY', 'TX', 'FL', 'IL', 'WA', 'MA'], NUM_MEMBERS),
    'zip_code': [str(np.random.randint(10000, 99999)) for _ in range(NUM_MEMBERS)],
    'email': [f'member{i}@example.com' for i in range(1, NUM_MEMBERS + 1)],
    'phone': [f'555-{np.random.randint(100,999)}-{np.random.randint(1000,9999)}' for _ in range(NUM_MEMBERS)],
    'high_risk_flag': np.random.choice([True, False], NUM_MEMBERS, p=[0.15, 0.85]),  # 15% high risk
    'created_at': pd.date_range(start='2022-01-01', end='2023-12-31', periods=NUM_MEMBERS)
})

# Add some nulls for data quality testing (2% missing emails)
null_indices = np.random.choice(NUM_MEMBERS, int(NUM_MEMBERS * 0.02), replace=False)
members.loc[null_indices, 'email'] = None

# ============================================================================
# 3. ENROLLMENTS
# ============================================================================
print("Generating enrollments...")

# 95% of members enroll in screening program
enrolled_members = members.sample(int(NUM_MEMBERS * 0.95))

enrollments = pd.DataFrame({
    'enrollment_id': [f'ENR{str(i).zfill(5)}' for i in range(1, len(enrolled_members) + 1)],
    'member_id': enrolled_members['member_id'].values,
    'employer_id': enrolled_members['employer_id'].values,
    'enrollment_date': pd.date_range(start=START_DATE, end='2024-12-31', periods=len(enrolled_members)),
    'enrollment_channel': np.random.choice(['Email', 'Portal', 'Phone', 'HR Event'], len(enrolled_members), p=[0.5, 0.3, 0.15, 0.05]),
    'status': np.random.choice(['Active', 'Completed', 'Inactive'], len(enrolled_members), p=[0.6, 0.3, 0.1]),
    'consent_given': True  # All enrolled have consent
})

# ============================================================================
# 4. PROVIDERS
# ============================================================================
print("Generating providers...")

specialties = ['Radiology', 'Oncology', 'Primary Care', 'Gastroenterology', 'Pathology']

providers = pd.DataFrame({
    'provider_id': [f'PROV{str(i).zfill(4)}' for i in range(1, NUM_PROVIDERS + 1)],
    'provider_name': [f'Dr. {chr(65 + (i % 26))}. Provider{i}' for i in range(NUM_PROVIDERS)],
    'specialty': np.random.choice(specialties, NUM_PROVIDERS),
    'state': np.random.choice(['CA', 'NY', 'TX', 'FL', 'IL', 'WA', 'MA'], NUM_PROVIDERS),
    'npi_number': [f'NPI{np.random.randint(1000000000, 9999999999)}' for _ in range(NUM_PROVIDERS)]
})

# ============================================================================
# 5. SCREENINGS
# ============================================================================
print("Generating screenings...")

# Screening types by age/gender
def assign_screening_type(row):
    age = (datetime.now() - row['date_of_birth']).days / 365.25
    gender = row['gender']
    
    if gender == 'F' and age >= 40:
        # Women 40+ eligible for mammogram + colonoscopy
        return np.random.choice(['Mammogram', 'Colonoscopy'], p=[0.7, 0.3])
    elif gender == 'M' and age >= 50:
        # Men 50+ eligible for colonoscopy + prostate
        return np.random.choice(['Colonoscopy', 'Prostate Screening'], p=[0.6, 0.4])
    elif age >= 50:
        # All 50+ eligible for colonoscopy
        return 'Colonoscopy'
    else:
        # Younger: cervical or general health screening
        return np.random.choice(['Cervical Screening', 'General Health Screening'])

# Generate 1-5 screenings per enrolled member over 2 years
screenings_list = []
screening_id = 1

for _, enrollment in enrollments.iterrows():
    member = members[members['member_id'] == enrollment['member_id']].iloc[0]
    
    # Number of screenings (more engaged members have more)
    num_screenings = np.random.choice([1, 2, 3, 4, 5], p=[0.4, 0.3, 0.15, 0.10, 0.05])
    
    for s in range(num_screenings):
        screening_date = enrollment['enrollment_date'] + timedelta(days=np.random.randint(30, 730))
        
        if screening_date > END_DATE:
            continue
            
        screening_type = assign_screening_type(member)
        
        # Results: 90% normal, 8% abnormal, 2% cancer detected
        result = np.random.choice(['Normal', 'Abnormal - Benign', 'Cancer Detected'], 
                                   p=[0.90, 0.08, 0.02])
        
        screenings_list.append({
            'screening_id': f'SCR{str(screening_id).zfill(6)}',
            'member_id': enrollment['member_id'],
            'employer_id': enrollment['employer_id'],
            'provider_id': np.random.choice(providers['provider_id']),
            'screening_type': screening_type,
            'screening_date': screening_date,
            'result': result,
            'result_date': screening_date + timedelta(days=np.random.randint(7, 21)),  # Results in 1-3 weeks
            'follow_up_needed': result != 'Normal',
            'follow_up_completed': np.random.choice([True, False], p=[0.75, 0.25]) if result != 'Normal' else None,
            'cost': np.random.randint(200, 2000)
        })
        
        screening_id += 1

screenings = pd.DataFrame(screenings_list)

# Add some late-arriving data (5% of screenings have result_date in future)
late_indices = screenings.sample(int(len(screenings) * 0.05)).index
screenings.loc[late_indices, 'result_date'] = screenings.loc[late_indices, 'result_date'] + timedelta(days=30)

# ============================================================================
# 6. CLAIMS (Medical claims for follow-up care)
# ============================================================================
print("Generating claims...")

# Generate claims for members with abnormal/cancer results
abnormal_screenings = screenings[screenings['result'].isin(['Abnormal - Benign', 'Cancer Detected'])]

claims_list = []
claim_id = 1

for _, screening in abnormal_screenings.iterrows():
    # 1-3 claims per abnormal screening (imaging, biopsy, consultation)
    num_claims = np.random.randint(1, 4)
    
    for c in range(num_claims):
        claim_date = screening['result_date'] + timedelta(days=np.random.randint(1, 90))
        
        # Procedure types for follow-up
        if screening['screening_type'] == 'Mammogram':
            procedures = ['Diagnostic Mammogram', 'Breast Ultrasound', 'Breast Biopsy', 'MRI']
            icd10_codes = ['C50.9', 'D48.6', 'N60.1']  # Breast cancer, benign neoplasm, fibrocystic
        elif screening['screening_type'] == 'Colonoscopy':
            procedures = ['Polypectomy', 'Follow-up Colonoscopy', 'CT Colonography']
            icd10_codes = ['C18.9', 'D12.6', 'K63.5']  # Colon cancer, polyp, polyp
        else:
            procedures = ['Consultation', 'Imaging', 'Biopsy', 'Lab Test']
            icd10_codes = ['C80.1', 'D48.9', 'R76.0']  # Malignant neoplasm, benign
        
        claims_list.append({
            'claim_id': f'CLM{str(claim_id).zfill(6)}',
            'member_id': screening['member_id'],
            'provider_id': screening['provider_id'],
            'claim_date': claim_date,
            'service_date': claim_date,
            'procedure_code': f'CPT{np.random.randint(10000, 99999)}',
            'procedure_description': np.random.choice(procedures),
            'diagnosis_code': np.random.choice(icd10_codes),
            'claim_amount': np.random.randint(500, 5000),
            'paid_amount': np.random.randint(400, 4500),
            'claim_status': np.random.choice(['Paid', 'Pending', 'Denied'], p=[0.85, 0.10, 0.05])
        })
        
        claim_id += 1

claims = pd.DataFrame(claims_list) if claims_list else pd.DataFrame()

# ============================================================================
# 7. APP EVENTS (User engagement with Color's portal)
# ============================================================================
print("Generating app events...")

event_types = [
    'login', 'view_results', 'schedule_screening', 'update_profile', 
    'download_report', 'chat_support', 'view_education_content', 'logout'
]

app_events_list = []
event_id = 1

for _, member in enrolled_members.iterrows():
    # Engagement pattern: 70% active, 20% moderate, 10% low
    engagement_level = np.random.choice(['high', 'medium', 'low'], p=[0.7, 0.2, 0.1])
    
    if engagement_level == 'high':
        num_events = np.random.randint(20, 100)
    elif engagement_level == 'medium':
        num_events = np.random.randint(5, 20)
    else:
        num_events = np.random.randint(1, 5)
    
    enrollment_date = enrollments[enrollments['member_id'] == member['member_id']]['enrollment_date'].iloc[0]
    
    for e in range(num_events):
        event_date = enrollment_date + timedelta(days=np.random.randint(0, 730))
        
        if event_date > END_DATE:
            continue
        
        app_events_list.append({
            'event_id': f'EVT{str(event_id).zfill(7)}',
            'member_id': member['member_id'],
            'event_type': np.random.choice(event_types),
            'event_timestamp': event_date + timedelta(hours=np.random.randint(0, 24)),
            'session_id': f'SES{np.random.randint(100000, 999999)}',
            'device_type': np.random.choice(['Desktop', 'Mobile', 'Tablet'], p=[0.5, 0.4, 0.1])
        })
        
        event_id += 1

app_events = pd.DataFrame(app_events_list)

# ============================================================================
# SAVE TO CSV
# ============================================================================
print("\nSaving CSVs to seeds/...")

# Create seeds directory if it doesn't exist
import os
os.makedirs('seeds', exist_ok=True)

employers.to_csv('seeds/raw_employers.csv', index=False)
members.to_csv('seeds/raw_members.csv', index=False)
enrollments.to_csv('seeds/raw_enrollments.csv', index=False)
providers.to_csv('seeds/raw_providers.csv', index=False)
screenings.to_csv('seeds/raw_screenings.csv', index=False)
if not claims.empty:
    claims.to_csv('seeds/raw_claims.csv', index=False)
app_events.to_csv('seeds/raw_app_events.csv', index=False)

# ============================================================================
# SUMMARY STATISTICS
# ============================================================================
print("\n" + "="*60)
print("SYNTHETIC DATA GENERATION COMPLETE!")
print("="*60)
print(f"\n📊 Data Summary:")
print(f"  Employers:      {len(employers):,}")
print(f"  Members:        {len(members):,}")
print(f"  Enrollments:    {len(enrollments):,}")
print(f"  Providers:      {len(providers):,}")
print(f"  Screenings:     {len(screenings):,}")
print(f"  Claims:         {len(claims):,}")
print(f"  App Events:     {len(app_events):,}")
print(f"\n📅 Date Range:    {START_DATE.date()} to {END_DATE.date()}")
print(f"\n✅ Files saved to seeds/ directory")
print(f"\nNext steps:")
print(f"  1. Run: dbt seed")
print(f"  2. Run: dbt run")
print(f"  3. Run: dbt test")
print("="*60)