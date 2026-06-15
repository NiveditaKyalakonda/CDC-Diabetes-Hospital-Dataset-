# Hospital Readmission Analytics — PowerShell launcher
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Hospital Readmission Analytics Dashboard" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Starting app on http://localhost:8501" -ForegroundColor Green
Write-Host ""
streamlit run app/Home.py
