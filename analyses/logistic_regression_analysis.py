import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sys import exit
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    confusion_matrix, classification_report, roc_auc_score, roc_curve
)
from sklearn.preprocessing import StandardScaler
import warnings
warnings.filterwarnings('ignore')

# Set display options
pd.set_option('display.max_columns', None)
pd.set_option('display.width', None)

print("="*80)
print("FOLLOW-UP COMPLETION PREDICTION - LOGISTIC REGRESSION ANALYSIS")
print("="*80)

# =============================================================================
# 1. LOAD DATA
# =============================================================================
print("\n📊 STEP 1: Loading data...")

try:
    df = pd.read_csv('/Users/maxvargas/Downloads/followup_analysis_data.csv')
    print(f"✅ Loaded {len(df)} records")
except FileNotFoundError:
    print("❌ Error: followup_analysis_data.csv not found!")
    print("   Export data from BigQuery first.")
    exit(1)

# =============================================================================
# 2. EXPLORATORY DATA ANALYSIS
# =============================================================================
print("\n📊 STEP 2: Exploratory Data Analysis")

print(f"\nDataset shape: {df.shape}")
print(f"\nOutcome distribution:")
print(df['outcome_binary'].value_counts())
print(f"Completion rate: {df['outcome_binary'].mean():.1%}")

print(f"\nMissing values:")
print(df.isnull().sum()[df.isnull().sum() > 0])

print(f"\n📈 Completion Rate by Predictor:")

print("\nAge Group:")
age_stats = df.groupby('age_group')['outcome_binary'].agg(['count', 'mean'])
age_stats.columns = ['Count', 'Completion Rate']
age_stats['Completion Rate'] = age_stats['Completion Rate'].apply(lambda x: f"{x:.1%}")
print(age_stats)

print("\nGender:")
gender_stats = df.groupby('gender')['outcome_binary'].agg(['count', 'mean'])
gender_stats.columns = ['Count', 'Completion Rate']
gender_stats['Completion Rate'] = gender_stats['Completion Rate'].apply(lambda x: f"{x:.1%}")
print(gender_stats)

print("\nScreening Type:")
screening_stats = df.groupby('screening_type')['outcome_binary'].agg(['count', 'mean'])
screening_stats.columns = ['Count', 'Completion Rate']
screening_stats['Completion Rate'] = screening_stats['Completion Rate'].apply(lambda x: f"{x:.1%}")
print(screening_stats)

print("\nDay of Week:")
day_stats = df.groupby('day_of_week_result_delivered')['outcome_binary'].agg(['count', 'mean'])
day_stats.columns = ['Count', 'Completion Rate']
day_stats['Completion Rate'] = day_stats['Completion Rate'].apply(lambda x: f"{x:.1%}")
print(day_stats)

print("\nDays to Result (continuous):")
print(f"  Mean: {df['days_to_result'].mean():.1f} days")
print(f"  Median: {df['days_to_result'].median():.1f} days")
print(f"  Range: {df['days_to_result'].min()}-{df['days_to_result'].max()} days")

# =============================================================================
# 3. PREPARE FEATURES FOR MODELING
# =============================================================================
print("\n🔧 STEP 3: Preparing features for modeling...")

# Define feature columns (one-hot encoded predictors)
feature_columns = [
    # Age (use 3 dummy variables, drop one to avoid multicollinearity)
    'age_40_49', 'age_50_64', 'age_65_plus',  # Under 40 is baseline
    
    # Gender (use 2 dummy variables)
    'gender_female', 'gender_other',  # Male is baseline
    
    # Screening type (use 4 dummy variables)
    'screening_colonoscopy', 'screening_prostate', 'screening_cervical', 'screening_other',  # Mammogram is baseline
    
    # Days to result (continuous)
    'days_to_result',
    
    # Day of week (use 6 dummy variables)
    'day_tuesday', 'day_wednesday', 'day_thursday', 'day_friday', 'day_saturday', 'day_sunday'  # Monday is baseline
]

# Extract features and target
X = df[feature_columns].copy()
y = df['outcome_binary'].copy()

print(f"✅ Features prepared: {X.shape[1]} predictors")
print(f"   Feature names: {', '.join(feature_columns)}")

# Check for missing values
if X.isnull().sum().sum() > 0:
    print(f"⚠️  Warning: {X.isnull().sum().sum()} missing values detected")
    X = X.fillna(0)
    
# =============================================================================
# 4. TRAIN/TEST SPLIT
# =============================================================================
print("\n✂️  STEP 4: Splitting data into train/test sets...")

X_train, X_test, y_train, y_test = train_test_split(
    X, y, 
    test_size=0.25,  # 75% train, 25% test
    random_state=42,
    stratify=y  # Maintain outcome distribution in both sets
)

print(f"✅ Train set: {len(X_train)} records ({len(X_train)/len(X)*100:.1f}%)")
print(f"✅ Test set:  {len(X_test)} records ({len(X_test)/len(X)*100:.1f}%)")
print(f"\nTrain outcome distribution:")
print(f"  Completed: {y_train.sum()} ({y_train.mean():.1%})")
print(f"  Not completed: {(~y_train.astype(bool)).sum()} ({(1-y_train.mean()):.1%})")

# =============================================================================
# 5. SCALE CONTINUOUS FEATURES
# =============================================================================
print("\n📏 STEP 5: Scaling continuous features...")

# Only scale days_to_result (continuous variable)
scaler = StandardScaler()
X_train_scaled = X_train.copy()
X_test_scaled = X_test.copy()

X_train_scaled['days_to_result'] = scaler.fit_transform(X_train[['days_to_result']])
X_test_scaled['days_to_result'] = scaler.transform(X_test[['days_to_result']])

print(f"✅ Scaled 'days_to_result' (mean=0, std=1)")

# =============================================================================
# 6. FIT LOGISTIC REGRESSION MODEL
# =============================================================================
print("\n🤖 STEP 6: Fitting logistic regression model...")

# Fit model
model = LogisticRegression(
    random_state=42,
    max_iter=1000,
    solver='lbfgs'
)

model.fit(X_train_scaled, y_train)

print(f"✅ Model trained successfully")
print(f"   Intercept: {model.intercept_[0]:.4f}")
print(f"   Number of iterations: {model.n_iter_[0]}")

# =============================================================================
# 7. MODEL COEFFICIENTS & INTERPRETATION
# =============================================================================
print("\n📊 STEP 7: Model Coefficients (Feature Importance)")

# Create coefficient dataframe
coef_df = pd.DataFrame({
    'Feature': feature_columns,
    'Coefficient': model.coef_[0],
    'Odds Ratio': np.exp(model.coef_[0])
})

coef_df['Abs_Coefficient'] = np.abs(coef_df['Coefficient'])
coef_df = coef_df.sort_values('Abs_Coefficient', ascending=False)

print("\nTop 10 Most Important Features:")
print(coef_df[['Feature', 'Coefficient', 'Odds Ratio']].head(10).to_string(index=False))

print("\n📖 Interpretation Guide:")
print("  - Positive coefficient = increases likelihood of follow-up completion")
print("  - Negative coefficient = decreases likelihood of follow-up completion")
print("  - Odds Ratio > 1 = increases odds")
print("  - Odds Ratio < 1 = decreases odds")

# =============================================================================
# 8. PREDICTIONS & EVALUATION
# =============================================================================
print("\n🎯 STEP 8: Making predictions and evaluating model...")

# Predict on test set
y_pred = model.predict(X_test_scaled)
y_pred_proba = model.predict_proba(X_test_scaled)[:, 1]

# Calculate metrics
accuracy = accuracy_score(y_test, y_pred)
precision = precision_score(y_test, y_pred)
recall = recall_score(y_test, y_pred)
f1 = f1_score(y_test, y_pred)
roc_auc = roc_auc_score(y_test, y_pred_proba)

print("\n📊 MODEL PERFORMANCE (Test Set):")
print(f"  Accuracy:  {accuracy:.3f}")
print(f"  Precision: {precision:.3f} (of predicted completions, {precision:.1%} actually completed)")
print(f"  Recall:    {recall:.3f} (of actual completions, {recall:.1%} were predicted)")
print(f"  F1-Score:  {f1:.3f}")
print(f"  ROC-AUC:   {roc_auc:.3f}")

# Confusion matrix
cm = confusion_matrix(y_test, y_pred)
print("\n📊 Confusion Matrix:")
print(f"                 Predicted No  Predicted Yes")
print(f"  Actual No:     {cm[0,0]:12d}  {cm[0,1]:13d}")
print(f"  Actual Yes:    {cm[1,0]:12d}  {cm[1,1]:13d}")

# Classification report
print("\n📊 Detailed Classification Report:")
print(classification_report(y_test, y_pred, target_names=['Not Completed', 'Completed']))

# =============================================================================
# 9. RISK SCORING
# =============================================================================
print("\n🎲 STEP 9: Generating risk scores...")

# Add predictions to full dataset
X_scaled_full = X.copy()
X_scaled_full['days_to_result'] = scaler.transform(X[['days_to_result']])

df['predicted_completion_probability'] = model.predict_proba(X_scaled_full)[:, 1]
df['predicted_outcome'] = model.predict(X_scaled_full)

# Create risk categories
df['risk_category'] = pd.cut(
    df['predicted_completion_probability'],
    bins=[0, 0.4, 0.7, 1.0],
    labels=['High Risk (Low Completion Likelihood)', 
            'Medium Risk (Moderate Completion Likelihood)', 
            'Low Risk (High Completion Likelihood)']
)

print("\n📊 Risk Distribution:")
print(df['risk_category'].value_counts().sort_index())

print("\n📊 Actual Completion Rate by Risk Category:")
risk_analysis = df.groupby('risk_category')['outcome_binary'].agg(['count', 'mean'])
risk_analysis.columns = ['Count', 'Actual Completion Rate']
risk_analysis['Actual Completion Rate'] = risk_analysis['Actual Completion Rate'].apply(lambda x: f"{x:.1%}")
print(risk_analysis)

# =============================================================================
# 10. SAVE RESULTS
# =============================================================================
print("\n💾 STEP 10: Saving results...")

# Save predictions
df[['screening_id', 'outcome_binary', 'predicted_completion_probability', 
    'predicted_outcome', 'risk_category']].to_csv('followup_predictions.csv', index=False)
print("✅ Saved predictions to: followup_predictions.csv")

# Save coefficients
coef_df.to_csv('model_coefficients.csv', index=False)
print("✅ Saved coefficients to: model_coefficients.csv")

# Save model summary
with open('model_summary.txt', 'w') as f:
    f.write("LOGISTIC REGRESSION MODEL SUMMARY\n")
    f.write("="*80 + "\n\n")
    f.write(f"Dataset Size: {len(df)} follow-up records\n")
    f.write(f"Train/Test Split: 75%/25%\n")
    f.write(f"Number of Features: {len(feature_columns)}\n\n")
    f.write("MODEL PERFORMANCE (Test Set):\n")
    f.write(f"  Accuracy:  {accuracy:.3f}\n")
    f.write(f"  Precision: {precision:.3f}\n")
    f.write(f"  Recall:    {recall:.3f}\n")
    f.write(f"  F1-Score:  {f1:.3f}\n")
    f.write(f"  ROC-AUC:   {roc_auc:.3f}\n\n")
    f.write("TOP 5 MOST IMPORTANT FEATURES:\n")
    for idx, row in coef_df.head(5).iterrows():
        f.write(f"  {row['Feature']}: {row['Coefficient']:.4f} (OR: {row['Odds Ratio']:.3f})\n")

print("✅ Saved model summary to: model_summary.txt")

# =============================================================================
# FINAL SUMMARY
# =============================================================================
print("\n" + "="*80)
print("✅ ANALYSIS COMPLETE!")
print("="*80)
print("\n📁 Generated Files:")
print("  1. followup_predictions.csv - Predictions for all records")
print("  2. model_coefficients.csv - Feature coefficients and odds ratios")
print("  3. model_summary.txt - Model performance summary")
print("\n📊 Key Findings:")
print(f"  - Model Accuracy: {accuracy:.1%}")
print(f"  - ROC-AUC Score: {roc_auc:.3f}")
print(f"  - {(df['risk_category'] == 'High Risk (Low Completion Likelihood)').sum()} members identified as high risk for non-completion")
print("\n💡 Next Steps:")
print("  - Review model_coefficients.csv to understand feature impact")
print("  - Use followup_predictions.csv to prioritize outreach to high-risk members")
print("  - Load predictions back into BigQuery for operational use")
print("="*80)