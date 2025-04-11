/**
 * WindrunnerRotations - Main JavaScript
 * Author: VortexQ8
 */

document.addEventListener('DOMContentLoaded', function() {
    // Initialize all components
    initNavigation();
    initTestimonialSlider();
    initClassSelector();
    
    // Scroll animation handlers
    window.addEventListener('scroll', function() {
        handleHeaderScroll();
    });
});

/**
 * Handle navigation behavior
 */
function initNavigation() {
    const header = document.querySelector('.site-header');
    const mobileMenuToggle = document.querySelector('.mobile-menu-toggle');
    
    // Mobile menu toggle
    if (mobileMenuToggle) {
        mobileMenuToggle.addEventListener('click', function() {
            document.body.classList.toggle('mobile-menu-active');
        });
    }
    
    // Close mobile menu when clicking outside
    document.addEventListener('click', function(event) {
        if (document.body.classList.contains('mobile-menu-active') && 
            !event.target.closest('.main-nav')) {
            document.body.classList.remove('mobile-menu-active');
        }
    });
    
    // Initial header state
    handleHeaderScroll();
}

/**
 * Handle header appearance on scroll
 */
function handleHeaderScroll() {
    const header = document.querySelector('.site-header');
    if (window.scrollY > 50) {
        header.classList.add('scrolled');
    } else {
        header.classList.remove('scrolled');
    }
}

/**
 * Initialize testimonial slider
 */
function initTestimonialSlider() {
    const testimonials = document.querySelectorAll('.testimonial');
    const prevButton = document.getElementById('testimonial-prev');
    const nextButton = document.getElementById('testimonial-next');
    
    if (!testimonials.length) return;
    
    let currentIndex = 0;
    
    // Show first testimonial
    testimonials[currentIndex].classList.add('active');
    
    // Previous button handler
    if (prevButton) {
        prevButton.addEventListener('click', function() {
            testimonials[currentIndex].classList.remove('active');
            currentIndex = (currentIndex - 1 + testimonials.length) % testimonials.length;
            testimonials[currentIndex].classList.add('active');
        });
    }
    
    // Next button handler
    if (nextButton) {
        nextButton.addEventListener('click', function() {
            testimonials[currentIndex].classList.remove('active');
            currentIndex = (currentIndex + 1) % testimonials.length;
            testimonials[currentIndex].classList.add('active');
        });
    }
    
    // Auto-rotate testimonials
    setInterval(function() {
        if (document.visibilityState === 'visible') {
            testimonials[currentIndex].classList.remove('active');
            currentIndex = (currentIndex + 1) % testimonials.length;
            testimonials[currentIndex].classList.add('active');
        }
    }, 8000);
}

/**
 * Initialize class selector in the showcase
 */
function initClassSelector() {
    // Class data with colors (matching WoW class colors)
    const classData = [
        { id: 'warrior', name: 'Warrior', color: '#C79C6E', icon: 'images/classes/warrior.png' },
        { id: 'paladin', name: 'Paladin', color: '#F58CBA', icon: 'images/classes/paladin.png' },
        { id: 'hunter', name: 'Hunter', color: '#ABD473', icon: 'images/classes/hunter.png' },
        { id: 'rogue', name: 'Rogue', color: '#FFF569', icon: 'images/classes/rogue.png' },
        { id: 'priest', name: 'Priest', color: '#FFFFFF', icon: 'images/classes/priest.png' },
        { id: 'shaman', name: 'Shaman', color: '#0070DE', icon: 'images/classes/shaman.png' },
        { id: 'mage', name: 'Mage', color: '#69CCF0', icon: 'images/classes/mage.png' },
        { id: 'warlock', name: 'Warlock', color: '#9482C9', icon: 'images/classes/warlock.png' },
        { id: 'monk', name: 'Monk', color: '#00FF96', icon: 'images/classes/monk.png' },
        { id: 'druid', name: 'Druid', color: '#FF7D0A', icon: 'images/classes/druid.png' },
        { id: 'dh', name: 'Demon Hunter', color: '#A330C9', icon: 'images/classes/dh.png' },
        { id: 'dk', name: 'Death Knight', color: '#C41F3B', icon: 'images/classes/dk.png' },
        { id: 'evoker', name: 'Evoker', color: '#33937F', icon: 'images/classes/evoker.png' }
    ];
    
    const classIconsContainer = document.getElementById('class-icons');
    const className = document.getElementById('class-name');
    const classDesc = document.getElementById('class-desc');
    const classGuideBtn = document.getElementById('class-guide-btn');
    
    if (!classIconsContainer) return;
    
    // Create class icons
    classData.forEach(classInfo => {
        const classIcon = document.createElement('div');
        classIcon.className = 'class-icon';
        classIcon.dataset.class = classInfo.id;
        
        if (classInfo.id === 'mage') {
            classIcon.classList.add('active');
        }
        
        classIcon.innerHTML = `<img src="${classInfo.icon}" alt="${classInfo.name}" title="${classInfo.name}">`;
        
        classIcon.addEventListener('click', () => {
            // Update active class
            document.querySelector('.class-icon.active')?.classList.remove('active');
            classIcon.classList.add('active');
            
            // Update class info
            if (className) {
                className.textContent = classInfo.name;
                className.style.color = classInfo.color;
            }
            
            if (classDesc) {
                classDesc.textContent = `Our ${classInfo.name} rotation module features specialized logic for all specs, including cooldown management, AoE optimization, and encounter-specific adjustments.`;
            }
            
            if (classGuideBtn) {
                classGuideBtn.textContent = `View ${classInfo.name} Guide`;
                classGuideBtn.href = `guides/${classInfo.id}.html`;
            }
            
            // Update 3D model if available
            if (window.loadClassModel) {
                window.loadClassModel(classInfo.id);
            }
        });
        
        classIconsContainer.appendChild(classIcon);
    });
}

/**
 * Handle form submissions
 */
function handleFormSubmit(event, formId) {
    event.preventDefault();
    const form = document.getElementById(formId);
    
    // Simple client-side validation
    const requiredFields = form.querySelectorAll('[required]');
    let isValid = true;
    
    requiredFields.forEach(field => {
        if (!field.value.trim()) {
            isValid = false;
            field.classList.add('error');
        } else {
            field.classList.remove('error');
        }
    });
    
    if (!isValid) {
        showFormMessage(form, 'Please fill out all required fields.', 'error');
        return;
    }
    
    // Here you would normally send the form data to your server
    // For now, we'll simulate a successful submission
    
    // Show success message
    showFormMessage(form, 'Form submitted successfully! We will get back to you soon.', 'success');
    
    // Reset form
    form.reset();
}

/**
 * Display form message
 */
function showFormMessage(form, message, type) {
    // Get or create message element
    let messageEl = form.querySelector('.form-message');
    
    if (!messageEl) {
        messageEl = document.createElement('div');
        messageEl.className = 'form-message';
        form.appendChild(messageEl);
    }
    
    // Set message content and type
    messageEl.textContent = message;
    messageEl.className = `form-message ${type}`;
    
    // Automatically hide after 5 seconds
    setTimeout(() => {
        messageEl.classList.add('hide');
    }, 5000);
}

/**
 * Dynamic placeholder for API key validation
 * This will be replaced with actual implementation when you set up your API
 */
function validateApiKey(apiKey) {
    // Placeholder for API validation
    // This will be replaced with actual API validation when your backend is ready
    console.log('API key validation will be implemented when backend is ready');
    
    // For now, simulate successful validation with the key "DEMO-KEY"
    return apiKey === 'DEMO-KEY';
}