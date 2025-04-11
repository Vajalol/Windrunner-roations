/**
 * WindrunnerRotations - Main JavaScript
 * Author: VortexQ8
 */

document.addEventListener('DOMContentLoaded', function() {
    // Initialize all components
    initNavigation();
    handleHeaderScroll();
    initTestimonialSlider();
    initClassSelector();
    initMagicalEffects();
    
    // Set up form submissions
    const forms = document.querySelectorAll('form');
    forms.forEach(form => {
        form.addEventListener('submit', event => handleFormSubmit(event, form.id));
    });
});

/**
 * Handle navigation behavior
 */
function initNavigation() {
    const mobileToggle = document.querySelector('.mobile-menu-toggle');
    const navLinks = document.querySelector('.nav-links');
    const navButtons = document.querySelector('.nav-buttons');
    
    if (mobileToggle) {
        mobileToggle.addEventListener('click', function() {
            this.classList.toggle('active');
            navLinks.classList.toggle('active');
            navButtons.classList.toggle('active');
        });
    }
    
    // Add smooth scrolling to all navigation links with hash
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            const targetId = this.getAttribute('href');
            
            // Skip if it's just #
            if (targetId === '#') return;
            
            const targetElement = document.querySelector(targetId);
            if (targetElement) {
                e.preventDefault();
                
                // Add magical effect before scrolling
                addMagicalTrail(e);
                
                // Close mobile menu if open
                if (mobileToggle && mobileToggle.classList.contains('active')) {
                    mobileToggle.click();
                }
                
                // Smooth scroll to target
                window.scrollTo({
                    top: targetElement.offsetTop - 80,
                    behavior: 'smooth'
                });
            }
        });
    });
}

/**
 * Handle header appearance on scroll
 */
function handleHeaderScroll() {
    const header = document.querySelector('.site-header');
    
    if (header) {
        window.addEventListener('scroll', function() {
            if (window.scrollY > 50) {
                header.classList.add('scrolled');
            } else {
                header.classList.remove('scrolled');
            }
        });
    }
}

/**
 * Initialize testimonial slider
 */
function initTestimonialSlider() {
    const testimonials = document.querySelectorAll('.testimonial');
    const prevButton = document.querySelector('.testimonial-prev');
    const nextButton = document.querySelector('.testimonial-next');
    
    if (testimonials.length === 0) return;
    
    let currentIndex = 0;
    
    // Display current testimonial
    function showTestimonial(index) {
        // Hide all testimonials
        testimonials.forEach(testimonial => {
            testimonial.classList.remove('active');
        });
        
        // Show the current testimonial
        testimonials[index].classList.add('active');
    }
    
    // Event listeners for navigation
    if (prevButton) {
        prevButton.addEventListener('click', function() {
            // Add magical effect on button click
            addButtonPulse(this);
            
            currentIndex--;
            if (currentIndex < 0) {
                currentIndex = testimonials.length - 1;
            }
            showTestimonial(currentIndex);
        });
    }
    
    if (nextButton) {
        nextButton.addEventListener('click', function() {
            // Add magical effect on button click
            addButtonPulse(this);
            
            currentIndex++;
            if (currentIndex >= testimonials.length) {
                currentIndex = 0;
            }
            showTestimonial(currentIndex);
        });
    }
    
    // Auto-rotate testimonials
    setInterval(function() {
        if (!document.hidden) {
            currentIndex++;
            if (currentIndex >= testimonials.length) {
                currentIndex = 0;
            }
            showTestimonial(currentIndex);
        }
    }, 8000);
}

/**
 * Initialize class selector in the showcase
 */
function initClassSelector() {
    const classIcons = document.querySelectorAll('.class-icon');
    const classInfoContainer = document.querySelector('.class-info');
    const classModelContainer = document.getElementById('class-model');
    
    if (classIcons.length === 0 || !classInfoContainer) return;
    
    // Class data - all the different class specializations
    const classData = {
        'warrior': {
            name: 'Warrior',
            desc: 'Dominate the battlefield with our optimized Warrior rotations. Built from the ground up to maximize your damage, survivability, and utility in any situation.',
            specs: ['Arms', 'Fury', 'Protection'],
            color: '#C69B6D'
        },
        'paladin': {
            name: 'Paladin',
            desc: 'Righteous power meets optimal DPS. Our Paladin rotations ensure that you\'re always using the right abilities at the right time, whether healing, tanking, or dealing damage.',
            specs: ['Holy', 'Protection', 'Retribution'],
            color: '#F48CBA'
        },
        'hunter': {
            name: 'Hunter',
            desc: 'Master the wilderness with precision. Our Hunter rotations maximize your pet management, trap usage, and damage rotation for peak performance.',
            specs: ['Beast Mastery', 'Marksmanship', 'Survival'],
            color: '#AAD372'
        },
        'rogue': {
            name: 'Rogue',
            desc: 'Strike from the shadows with deadly efficiency. Our Rogue rotations optimize your energy usage, combo point generation, and cooldown management.',
            specs: ['Assassination', 'Outlaw', 'Subtlety'],
            color: '#FFF468'
        },
        'priest': {
            name: 'Priest',
            desc: 'Channel divine power or shadow magic with equal mastery. Our Priest rotations adapt to healing demands or maximize damage output based on your spec.',
            specs: ['Discipline', 'Holy', 'Shadow'],
            color: '#FFFFFF'
        },
        'shaman': {
            name: 'Shaman',
            desc: 'Command the elements with precision. Our Shaman rotations help you unleash nature\'s fury, heal allies, or bolster your team with perfect timing.',
            specs: ['Elemental', 'Enhancement', 'Restoration'],
            color: '#0070DD'
        },
        'mage': {
            name: 'Mage',
            desc: 'Harness arcane, fire, and frost with unmatched skill. Our Mage rotations maximize your spell sequences, procs, and cooldown usage for optimal damage.',
            specs: ['Arcane', 'Fire', 'Frost'],
            color: '#3FC7EB'
        },
        'warlock': {
            name: 'Warlock',
            desc: 'Master the dark arts with demonic precision. Our Warlock rotations optimize your DoT management, demon control, and soul shard usage for maximum damage.',
            specs: ['Affliction', 'Demonology', 'Destruction'],
            color: '#8788EE'
        },
        'monk': {
            name: 'Monk',
            desc: 'Balance mind, body, and spirit for perfect harmony. Our Monk rotations maximize your Chi generation, utilization, and ability timing.',
            specs: ['Brewmaster', 'Mistweaver', 'Windwalker'],
            color: '#00FF98'
        },
        'druid': {
            name: 'Druid',
            desc: 'Shapeshift with purpose and precision. Our Druid rotations adapt to every form and role, ensuring optimal performance whether you\'re healing, tanking, or dealing damage.',
            specs: ['Balance', 'Feral', 'Guardian', 'Restoration'],
            color: '#FF7C0A'
        },
        'demon-hunter': {
            name: 'Demon Hunter',
            desc: 'Unleash your inner demon with calculated aggression. Our Demon Hunter rotations optimize your Fury generation, eye beam timing, and metamorphosis usage.',
            specs: ['Havoc', 'Vengeance'],
            color: '#A330C9'
        },
        'death-knight': {
            name: 'Death Knight',
            desc: 'Command the power of death with cold precision. Our Death Knight rotations maximize your rune usage, disease management, and cooldown timing.',
            specs: ['Blood', 'Frost', 'Unholy'],
            color: '#C41E3A'
        },
        'evoker': {
            name: 'Evoker',
            desc: 'Channel the power of the dragonflights with draconic precision. Our Evoker rotations optimize your empowered spells and cooldown usage for maximum effectiveness.',
            specs: ['Devastation', 'Preservation', 'Augmentation'],
            color: '#33937F'
        }
    };
    
    // Event listeners for class icons
    classIcons.forEach(icon => {
        icon.addEventListener('click', function() {
            // Remove active class from all icons
            classIcons.forEach(icon => {
                icon.classList.remove('active');
            });
            
            // Add active class to clicked icon
            this.classList.add('active');
            
            // Get class data
            const classId = this.getAttribute('data-class');
            const data = classData[classId];
            
            if (data) {
                // Update class info
                let specsHTML = '';
                data.specs.forEach(spec => {
                    specsHTML += `<div class="class-feature">${spec}</div>`;
                });
                
                classInfoContainer.innerHTML = `
                    <h3>${data.name} <span class="enchanted-text">Rotations</span></h3>
                    <p>${data.desc}</p>
                    <div class="class-features">
                        ${specsHTML}
                    </div>
                    <a href="#" class="btn btn-primary magical-btn">View ${data.name} Guide</a>
                `;
                
                // Update class model color
                if (classModelContainer) {
                    classModelContainer.style.borderColor = data.color;
                    
                    // Trigger magical effect
                    classModelContainer.classList.add('pulse-glow');
                    setTimeout(() => {
                        classModelContainer.classList.remove('pulse-glow');
                    }, 1000);
                }
                
                // Add magical effects
                addMagicalEffectToClassChange(this, data.color);
            }
        });
        
        // Add hover effects
        icon.addEventListener('mouseenter', function() {
            addMagicalHoverEffect(this);
        });
    });
}

/**
 * Initialize magical effects throughout the site
 */
function initMagicalEffects() {
    // Add magical effects to buttons
    const magicalButtons = document.querySelectorAll('.magical-btn');
    magicalButtons.forEach(button => {
        button.addEventListener('mouseenter', function(e) {
            addMagicalHoverEffect(this);
        });
        
        button.addEventListener('click', function(e) {
            addMagicalClickEffect(this, e);
        });
    });
    
    // Add shadow trail effects
    const shadowTrails = document.querySelectorAll('.shadow-trail');
    shadowTrails.forEach(element => {
        element.addEventListener('mouseenter', function() {
            this.classList.add('ghost-trail');
            setTimeout(() => {
                this.classList.remove('ghost-trail');
            }, 1000);
        });
    });
    
    // Add 3D card effects
    const cards3D = document.querySelectorAll('.card-3d');
    cards3D.forEach(card => {
        card.addEventListener('mousemove', function(e) {
            handle3DCardEffect(this, e);
        });
        
        card.addEventListener('mouseleave', function() {
            reset3DCardEffect(this);
        });
    });
    
    // Add enchanted text effects
    const enchantedTexts = document.querySelectorAll('.enchanted-text');
    enchantedTexts.forEach(text => {
        text.addEventListener('mouseenter', function() {
            this.classList.add('magical-text');
            setTimeout(() => {
                this.classList.remove('magical-text');
            }, 2000);
        });
    });
    
    // Add floating effect to specific elements
    const floatingElements = document.querySelectorAll('.sylvanas-glow, .wow-logo, .feature-icon');
    floatingElements.forEach(element => {
        element.classList.add('float');
    });
    
    // Random banshee wail effects
    setInterval(() => {
        if (Math.random() > 0.7) {
            addRandomBansheeEffect();
        }
    }, 5000);
}

/**
 * Handle form submissions
 */
function handleFormSubmit(event, formId) {
    event.preventDefault();
    
    const form = document.getElementById(formId);
    if (!form) return;
    
    // Get form data
    const formData = new FormData(form);
    const formObject = {};
    formData.forEach((value, key) => {
        formObject[key] = value;
    });
    
    // Example API call (replace with actual implementation)
    // This is a placeholder for your actual form submission logic
    console.log(`Form ${formId} submitted:`, formObject);
    
    // Show success message
    showFormMessage(form, 'Form submitted successfully!', 'success');
    
    // Reset form
    form.reset();
}

/**
 * Display form message
 */
function showFormMessage(form, message, type) {
    // Check if message element already exists
    let messageElement = form.querySelector('.form-message');
    
    if (!messageElement) {
        // Create message element
        messageElement = document.createElement('div');
        messageElement.classList.add('form-message');
        form.appendChild(messageElement);
    }
    
    // Set message content and type
    messageElement.textContent = message;
    messageElement.className = `form-message ${type}`;
    
    // Add magical effect
    messageElement.classList.add('fade-up-in');
    
    // Remove message after delay
    setTimeout(() => {
        messageElement.remove();
    }, 5000);
}

/**
 * Create magical effects for various interactions
 */
function addMagicalHoverEffect(element) {
    element.classList.add('pulse-glow');
    setTimeout(() => {
        element.classList.remove('pulse-glow');
    }, 1000);
}

function addMagicalClickEffect(element, e) {
    // Create a ripple effect
    const ripple = document.createElement('span');
    ripple.classList.add('ripple-effect');
    
    const rect = element.getBoundingClientRect();
    const size = Math.max(rect.width, rect.height);
    
    ripple.style.width = ripple.style.height = `${size}px`;
    ripple.style.left = `${e.clientX - rect.left - size/2}px`;
    ripple.style.top = `${e.clientY - rect.top - size/2}px`;
    
    element.appendChild(ripple);
    
    setTimeout(() => {
        ripple.remove();
    }, 600);
}

function addButtonPulse(button) {
    button.classList.add('shadow-pulse');
    setTimeout(() => {
        button.classList.remove('shadow-pulse');
    }, 1000);
}

function addMagicalTrail(e) {
    // Create a trail of banshee particles
    for (let i = 0; i < 5; i++) {
        setTimeout(() => {
            const particle = document.createElement('div');
            particle.classList.add('banshee-particle');
            
            // Random size
            const size = Math.random() * 15 + 5;
            particle.style.width = `${size}px`;
            particle.style.height = `${size}px`;
            
            // Position near the cursor
            particle.style.left = `${e.clientX + (Math.random() - 0.5) * 20}px`;
            particle.style.top = `${e.clientY + (Math.random() - 0.5) * 20}px`;
            
            // Random color (purple or blue)
            const color = Math.random() > 0.5 ? 
                'var(--sylvanas-purple)' : 'var(--sylvanas-blue)';
            particle.style.backgroundColor = color;
            
            document.body.appendChild(particle);
            
            // Animate and remove
            setTimeout(() => {
                particle.style.opacity = '0';
                particle.style.transform = `translate(${(Math.random() - 0.5) * 50}px, ${-Math.random() * 100}px) scale(0.5)`;
                
                setTimeout(() => {
                    particle.remove();
                }, 500);
            }, 10);
        }, i * 50);
    }
}

function addMagicalEffectToClassChange(element, color) {
    // Create magical class change effect
    for (let i = 0; i < 10; i++) {
        setTimeout(() => {
            const particle = document.createElement('div');
            particle.classList.add('class-change-particle');
            
            // Random size
            const size = Math.random() * 10 + 5;
            particle.style.width = `${size}px`;
            particle.style.height = `${size}px`;
            
            // Get element position
            const rect = element.getBoundingClientRect();
            const centerX = rect.left + rect.width / 2;
            const centerY = rect.top + rect.height / 2;
            
            // Position around the class icon
            const angle = Math.random() * Math.PI * 2;
            const distance = Math.random() * 50 + 30;
            
            particle.style.left = `${centerX + Math.cos(angle) * distance}px`;
            particle.style.top = `${centerY + Math.sin(angle) * distance}px`;
            
            // Use class color
            particle.style.backgroundColor = color;
            
            document.body.appendChild(particle);
            
            // Animate and remove
            setTimeout(() => {
                particle.style.opacity = '0';
                particle.style.transform = `translate(${Math.cos(angle) * 30}px, ${Math.sin(angle) * 30}px) scale(0)`;
                
                setTimeout(() => {
                    particle.remove();
                }, 500);
            }, 10);
        }, i * 30);
    }
}

function handle3DCardEffect(card, e) {
    const rect = card.getBoundingClientRect();
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;
    
    const mouseX = e.clientX;
    const mouseY = e.clientY;
    
    const rotateY = (mouseX - centerX) / 20;
    const rotateX = (centerY - mouseY) / 20;
    
    card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateZ(10px)`;
    
    // Add glow effect based on mouse position
    const glowX = (mouseX - rect.left) / rect.width * 100;
    const glowY = (mouseY - rect.top) / rect.height * 100;
    
    card.style.boxShadow = `
        0 10px 20px rgba(0,0,0,0.2),
        0 5px 10px rgba(0,0,0,0.2),
        0 0 20px rgba(153, 0, 255, 0.5),
        inset 0 0 0 0 rgba(153, 0, 255, 0),
        inset 0 0 0 0 var(--accent)
    `;
    
    card.style.backgroundImage = `
        radial-gradient(
            circle at ${glowX}% ${glowY}%, 
            rgba(153, 0, 255, 0.1) 0%, 
            rgba(0, 191, 255, 0.05) 25%, 
            transparent 50%
        )
    `;
}

function reset3DCardEffect(card) {
    card.style.transform = '';
    card.style.boxShadow = '';
    card.style.backgroundImage = '';
}

function addRandomBansheeEffect() {
    // Create a random banshee wail effect
    const banshee = document.createElement('div');
    banshee.classList.add('random-banshee');
    
    // Size and position
    const size = Math.random() * 100 + 50;
    banshee.style.width = `${size}px`;
    banshee.style.height = `${size * 2}px`;
    
    // Random position at the edge of the screen
    const side = Math.floor(Math.random() * 4); // 0: top, 1: right, 2: bottom, 3: left
    
    switch(side) {
        case 0: // top
            banshee.style.top = '-100px';
            banshee.style.left = `${Math.random() * window.innerWidth}px`;
            break;
        case 1: // right
            banshee.style.top = `${Math.random() * window.innerHeight}px`;
            banshee.style.left = `${window.innerWidth + 100}px`;
            break;
        case 2: // bottom
            banshee.style.top = `${window.innerHeight + 100}px`;
            banshee.style.left = `${Math.random() * window.innerWidth}px`;
            break;
        case 3: // left
            banshee.style.top = `${Math.random() * window.innerHeight}px`;
            banshee.style.left = '-100px';
            break;
    }
    
    // Random color (purple or blue)
    const color = Math.random() > 0.5 ? 
        'var(--sylvanas-purple)' : 'var(--sylvanas-blue)';
    banshee.style.backgroundColor = color;
    
    document.body.appendChild(banshee);
    
    // Calculate destination
    let destX, destY;
    switch(side) {
        case 0: // from top to bottom
            destX = Math.random() * window.innerWidth;
            destY = window.innerHeight + 100;
            break;
        case 1: // from right to left
            destX = -100;
            destY = Math.random() * window.innerHeight;
            break;
        case 2: // from bottom to top
            destX = Math.random() * window.innerWidth;
            destY = -100;
            break;
        case 3: // from left to right
            destX = window.innerWidth + 100;
            destY = Math.random() * window.innerHeight;
            break;
    }
    
    // Animate and remove
    banshee.style.opacity = '0.7';
    banshee.style.transform = `translate(${destX}px, ${destY}px) rotate(${Math.random() * 360}deg)`;
    
    setTimeout(() => {
        banshee.style.opacity = '0';
        setTimeout(() => {
            banshee.remove();
        }, 1000);
    }, 1000);
}

/**
 * Dynamic placeholder for API key validation
 * This will be replaced with actual implementation when you set up your API
 */
function validateApiKey(apiKey) {
    // Placeholder logic - replace with actual validation
    console.log(`Validating API key: ${apiKey}`);
    return new Promise((resolve, reject) => {
        // Simulate API call
        setTimeout(() => {
            if (apiKey && apiKey.length > 10) {
                resolve({ valid: true, message: 'API key is valid' });
            } else {
                reject({ valid: false, message: 'Invalid API key' });
            }
        }, 500);
    });
}