/**
 * WindrunnerRotations - Pricing Page JavaScript
 * Author: VortexQ8
 */

document.addEventListener('DOMContentLoaded', function() {
    // Initialize pricing page specific functionality
    initBillingToggle();
    initFaqAccordion();
});

/**
 * Handle billing toggle between monthly and yearly
 */
function initBillingToggle() {
    const billingToggle = document.getElementById('billingToggle');
    const monthlyLabel = document.querySelector('.billing-toggle .monthly');
    const yearlyLabel = document.querySelector('.billing-toggle .yearly');
    const monthlyPrices = document.querySelectorAll('.plan-price.monthly');
    const yearlyPrices = document.querySelectorAll('.plan-price.yearly');
    
    if (!billingToggle) return;
    
    // Initial state
    setVisibility(monthlyPrices, true);
    setVisibility(yearlyPrices, false);
    
    // Toggle handler
    billingToggle.addEventListener('change', function() {
        const isYearly = this.checked;
        
        // Toggle active class on labels
        monthlyLabel.classList.toggle('active', !isYearly);
        yearlyLabel.classList.toggle('active', isYearly);
        
        // Toggle price visibility
        setVisibility(monthlyPrices, !isYearly);
        setVisibility(yearlyPrices, isYearly);
    });
    
    // Helper to set visibility of elements
    function setVisibility(elements, isVisible) {
        elements.forEach(el => {
            el.style.display = isVisible ? 'block' : 'none';
        });
    }
}

/**
 * Initialize FAQ accordion
 */
function initFaqAccordion() {
    const faqItems = document.querySelectorAll('.faq-item');
    
    faqItems.forEach(item => {
        const question = item.querySelector('.faq-question');
        const answer = item.querySelector('.faq-answer');
        const icon = item.querySelector('.toggle-icon i');
        
        // Initially hide all answers
        answer.style.display = 'none';
        
        question.addEventListener('click', () => {
            // Toggle this item
            const isOpen = answer.style.display === 'block';
            
            // Close all answers first
            faqItems.forEach(otherItem => {
                const otherAnswer = otherItem.querySelector('.faq-answer');
                const otherIcon = otherItem.querySelector('.toggle-icon i');
                
                if (otherItem !== item) {
                    otherAnswer.style.display = 'none';
                    otherIcon.className = 'fas fa-plus';
                }
            });
            
            // Toggle current item
            answer.style.display = isOpen ? 'none' : 'block';
            icon.className = isOpen ? 'fas fa-plus' : 'fas fa-minus';
        });
    });
}

/**
 * Handle subscription selection
 * This is a placeholder for the actual subscription handling
 * that will be connected to your payment processor
 */
function handleSubscription(plan) {
    // Placeholder for actual subscription handler
    // This will be replaced with your payment processing integration
    
    // Get subscription period (monthly/yearly)
    const billingToggle = document.getElementById('billingToggle');
    const period = billingToggle && billingToggle.checked ? 'yearly' : 'monthly';
    
    console.log(`Selected plan: ${plan}, Period: ${period}`);
    
    // For now, simulate a redirect to a registration page
    // In production, this would initiate the payment process
    window.location.href = `register.html?plan=${plan}&period=${period}`;
}

/**
 * Scroll to pricing section
 */
function scrollToPricing() {
    const pricingSection = document.querySelector('.pricing-plans');
    if (pricingSection) {
        pricingSection.scrollIntoView({ behavior: 'smooth' });
    }
}