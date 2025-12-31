let progressInterval = null;
let progressStartTime = null;
let progressDuration = 0;
let progressType = 'bar';
let originalIcon = '';

window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (data.action === 'startProgress') {
        startProgress(data);
    } else if (data.action === 'stopProgress') {
        stopProgress(data.cancelled, data.success);
    }
});

function startProgress(data) {
    const { duration, label, icon, type, position, canCancel } = data;
    
    progressType = type || 'bar';
    progressDuration = duration || 5000;
    originalIcon = icon || '';
    
    if (progressType === 'bar') {
        startProgressBar(duration, label, icon, canCancel);
    } else if (progressType === 'circle') {
        startProgressCircle(duration, label, position, canCancel);
    }
}

function startProgressBar(duration, label, icon, canCancel) {
    const container = document.getElementById('progress-bar-container');
    const progressBar = document.getElementById('progress-bar');
    const progressLabel = document.getElementById('bar-label');
    const iconSpinner = document.getElementById('bar-spinner');
    const iconElement = document.getElementById('bar-icon');
    const progressBox = container.querySelector('.progress-box');
    
    progressBox.classList.remove('cancelled', 'success');
    progressBar.classList.remove('cancelled', 'success');
    iconElement.classList.remove('cancelled', 'success');
    
    progressBar.style.width = '0%';
    progressLabel.textContent = label || 'Processing...';
    
    if (icon) {
        iconSpinner.classList.add('hidden');
        iconElement.className = `progress-icon ${icon}`;
        iconElement.style.display = 'block';
    } else {
        iconSpinner.classList.remove('hidden');
        iconElement.style.display = 'none';
    }
    
    container.classList.remove('exit');
    container.classList.add('enter');
    
    progressStartTime = Date.now();
    
    if (progressInterval) {
        clearInterval(progressInterval);
    }
    
    progressInterval = setInterval(() => {
        const elapsed = Date.now() - progressStartTime;
        const progress = Math.min((elapsed / progressDuration) * 100, 100);
        
        progressBar.style.width = progress + '%';
        
        if (progress >= 100) {
            clearInterval(progressInterval);
            progressInterval = null;
        }
    }, 50);
}

function startProgressCircle(duration, label, position, canCancel) {
    const container = document.getElementById('progress-circle-container');
    const progressCircle = document.getElementById('progress-circle');
    const circleLabel = document.getElementById('circle-label');
    const circlePercent = document.getElementById('circle-percent');
    
    progressCircle.classList.remove('cancelled', 'success');
    
    container.classList.remove('position-middle', 'position-bottom');
    if (position === 'bottom') {
        container.classList.add('position-bottom');
    } else {
        container.classList.add('position-middle');
    }
    
    const circumference = 2 * Math.PI * 45;
    progressCircle.style.strokeDasharray = circumference;
    progressCircle.style.strokeDashoffset = circumference;
    circlePercent.textContent = '0%';
    
    if (label) {
        circleLabel.textContent = label;
        circleLabel.style.display = 'block';
    } else {
        circleLabel.style.display = 'none';
    }
    
    container.classList.remove('exit');
    container.classList.add('enter');
    
    progressStartTime = Date.now();
    
    if (progressInterval) {
        clearInterval(progressInterval);
    }
    
    progressInterval = setInterval(() => {
        const elapsed = Date.now() - progressStartTime;
        const progress = Math.min(elapsed / progressDuration, 1);
        const percent = Math.floor(progress * 100);
        
        const offset = circumference * (1 - progress);
        progressCircle.style.strokeDashoffset = offset;
        circlePercent.textContent = percent + '%';
        
        if (progress >= 1) {
            clearInterval(progressInterval);
            progressInterval = null;
        }
    }, 50);
}

function stopProgress(cancelled, success) {
    if (progressInterval) {
        clearInterval(progressInterval);
        progressInterval = null;
    }
    
    const barContainer = document.getElementById('progress-bar-container');
    const circleContainer = document.getElementById('progress-circle-container');
    
    if (cancelled) {
        if (progressType === 'bar') {
            const progressBox = barContainer.querySelector('.progress-box');
            const progressBar = document.getElementById('progress-bar');
            const progressLabel = document.getElementById('bar-label');
            const iconElement = document.getElementById('bar-icon');
            const iconSpinner = document.getElementById('bar-spinner');
            
            progressBox.classList.add('cancelled');
            progressBar.classList.add('cancelled');
            iconElement.classList.add('cancelled');
            progressLabel.textContent = 'Anulowano';
            
            iconSpinner.classList.add('hidden');
            iconElement.className = 'progress-icon fas fa-times cancelled';
            iconElement.style.display = 'block';
            
            setTimeout(() => {
                barContainer.classList.remove('enter');
                barContainer.classList.add('exit');
                
                setTimeout(() => {
                    barContainer.classList.remove('exit');
                    progressBox.classList.remove('cancelled');
                    progressBar.classList.remove('cancelled');
                    iconElement.classList.remove('cancelled');
                }, 300);
            }, 2000);
        } else {
            const progressCircle = document.getElementById('progress-circle');
            const circleLabel = document.getElementById('circle-label');
            
            progressCircle.classList.add('cancelled');
            if (circleLabel.textContent) {
                circleLabel.textContent = 'Anulowano';
            }
            
            setTimeout(() => {
                circleContainer.classList.remove('enter');
                circleContainer.classList.add('exit');
                
                setTimeout(() => {
                    circleContainer.classList.remove('exit');
                    progressCircle.classList.remove('cancelled');
                }, 300);
            }, 2000);
        }
    } else if (success) {
        if (progressType === 'bar') {
            const progressBox = barContainer.querySelector('.progress-box');
            const progressBar = document.getElementById('progress-bar');
            const progressLabel = document.getElementById('bar-label');
            const iconElement = document.getElementById('bar-icon');
            const iconSpinner = document.getElementById('bar-spinner');
            
            progressBar.style.width = '100%';
            
            progressBox.classList.add('success');
            progressBar.classList.add('success');
            iconElement.classList.add('success');
            progressLabel.textContent = 'Sukces';

            iconSpinner.classList.add('hidden');
            iconElement.className = 'progress-icon fas fa-check success';
            iconElement.style.display = 'block';
            
            setTimeout(() => {
                barContainer.classList.remove('enter');
                barContainer.classList.add('exit');
                
                setTimeout(() => {
                    barContainer.classList.remove('exit');
                    progressBox.classList.remove('success');
                    progressBar.classList.remove('success');
                    iconElement.classList.remove('success');
                }, 300);
            }, 2000);
        } else {
            const progressCircle = document.getElementById('progress-circle');
            const circleLabel = document.getElementById('circle-label');
            const circlePercent = document.getElementById('circle-percent');
            
            const circumference = 2 * Math.PI * 45;
            progressCircle.style.strokeDashoffset = 0;
            circlePercent.textContent = '100%';
            
            progressCircle.classList.add('success');
            if (circleLabel.textContent) {
                circleLabel.textContent = 'Sukces';
            }
            
            setTimeout(() => {
                circleContainer.classList.remove('enter');
                circleContainer.classList.add('exit');
                
                setTimeout(() => {
                    circleContainer.classList.remove('exit');
                    progressCircle.classList.remove('success');
                }, 300);
            }, 2000);
        }
    } else {
        if (barContainer.classList.contains('enter')) {
            barContainer.classList.remove('enter');
            barContainer.classList.add('exit');
            
            setTimeout(() => {
                barContainer.classList.remove('exit');
            }, 300);
        }
        
        if (circleContainer.classList.contains('enter')) {
            circleContainer.classList.remove('enter');
            circleContainer.classList.add('exit');
            
            setTimeout(() => {
                circleContainer.classList.remove('exit');
            }, 300);
        }
    }
    
    setTimeout(() => {
        document.getElementById('progress-bar').style.width = '0%';
        const circumference = 2 * Math.PI * 45;
        document.getElementById('progress-circle').style.strokeDashoffset = circumference;
        document.getElementById('circle-percent').textContent = '0%';
    }, (cancelled || success) ? 2300 : 300);
}
