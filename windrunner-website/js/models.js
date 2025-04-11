/**
 * WindrunnerRotations - 3D Models Integration
 * Author: VortexQ8
 */

document.addEventListener('DOMContentLoaded', function() {
    // Initialize 3D elements if Three.js is available
    if (typeof THREE !== 'undefined') {
        initHeroModel();
        initClassModel('mage'); // Start with mage as default
    } else {
        console.warn('Three.js library not found. 3D models will not be displayed.');
        
        // Fallback to static images for 3D models
        const heroModel = document.getElementById('hero-model');
        if (heroModel) {
            heroModel.innerHTML = '<img src="images/hero-fallback.png" alt="Hero Image" class="fallback-image">';
        }
        
        const classModel = document.getElementById('class-model');
        if (classModel) {
            classModel.innerHTML = '<img src="images/classes/mage-fallback.png" alt="Mage" class="fallback-image">';
        }
    }
});

/**
 * Initialize hero section 3D model
 */
function initHeroModel() {
    const container = document.getElementById('hero-model');
    if (!container) return;
    
    // Create scene
    const scene = new THREE.Scene();
    
    // Create camera
    const camera = new THREE.PerspectiveCamera(75, container.clientWidth / container.clientHeight, 0.1, 1000);
    camera.position.z = 5;
    
    // Create renderer
    const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true });
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.setPixelRatio(window.devicePixelRatio);
    container.appendChild(renderer.domElement);
    
    // Add lighting
    const ambientLight = new THREE.AmbientLight(0xcccccc, 0.5);
    scene.add(ambientLight);
    
    const pointLight = new THREE.PointLight(0xffffff, 0.8);
    pointLight.position.set(5, 5, 5);
    scene.add(pointLight);
    
    // Add magical particle effect
    const particles = createParticles();
    scene.add(particles);
    
    // Create a simple placeholder model (sphere with magical texture)
    const geometry = new THREE.SphereGeometry(2, 32, 32);
    
    // Create shader material for magical effect
    const material = new THREE.ShaderMaterial({
        uniforms: {
            time: { value: 0 }
        },
        vertexShader: `
            varying vec2 vUv;
            varying vec3 vPosition;
            
            void main() {
                vUv = uv;
                vPosition = position;
                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            }
        `,
        fragmentShader: `
            uniform float time;
            varying vec2 vUv;
            varying vec3 vPosition;
            
            void main() {
                // Create a magical swirling effect
                float r = length(vPosition.xy);
                float theta = atan(vPosition.y, vPosition.x);
                
                float pattern = sin(10.0 * theta + time * 2.0) * 0.5 + 0.5;
                
                vec3 color1 = vec3(0.1, 0.2, 0.7); // Deep blue
                vec3 color2 = vec3(0.7, 0.2, 0.8); // Purple
                vec3 color3 = vec3(1.0, 0.8, 0.1); // Gold
                
                // Mix colors based on pattern and position
                vec3 finalColor = mix(
                    mix(color1, color2, pattern),
                    color3,
                    sin(r * 3.0 + time) * 0.5 + 0.5
                );
                
                // Add some transparency
                float alpha = 0.7 + 0.3 * sin(r * 5.0 - time * 3.0);
                
                gl_FragColor = vec4(finalColor, alpha);
            }
        `,
        transparent: true
    });
    
    const sphere = new THREE.Mesh(geometry, material);
    scene.add(sphere);
    
    // Handle responsive resizing
    window.addEventListener('resize', onWindowResize);
    
    function onWindowResize() {
        camera.aspect = container.clientWidth / container.clientHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(container.clientWidth, container.clientHeight);
    }
    
    // Animation loop
    const clock = new THREE.Clock();
    
    function animate() {
        requestAnimationFrame(animate);
        
        const time = clock.getElapsedTime();
        
        // Update shader time uniform
        material.uniforms.time.value = time;
        
        // Rotate the sphere
        sphere.rotation.y = time * 0.3;
        sphere.rotation.z = time * 0.1;
        
        // Animate particles
        particles.rotation.y = time * 0.1;
        const positions = particles.geometry.attributes.position.array;
        
        for (let i = 0; i < positions.length; i += 3) {
            const i3 = i / 3;
            positions[i+1] += Math.sin(time + i3) * 0.01;
        }
        
        particles.geometry.attributes.position.needsUpdate = true;
        
        renderer.render(scene, camera);
    }
    
    animate();
}

/**
 * Initialize class model display
 */
function initClassModel(classId) {
    const container = document.getElementById('class-model');
    if (!container) return;
    
    // Create scene
    const scene = new THREE.Scene();
    
    // Create camera
    const camera = new THREE.PerspectiveCamera(75, container.clientWidth / container.clientHeight, 0.1, 1000);
    camera.position.z = 5;
    
    // Create renderer
    const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true });
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.setPixelRatio(window.devicePixelRatio);
    
    // Clear container
    container.innerHTML = '';
    container.appendChild(renderer.domElement);
    
    // Add lighting
    const ambientLight = new THREE.AmbientLight(0xcccccc, 0.5);
    scene.add(ambientLight);
    
    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(0, 1, 1);
    scene.add(directionalLight);
    
    // Get class color
    const classColors = {
        'warrior': 0xC79C6E,
        'paladin': 0xF58CBA,
        'hunter': 0xABD473,
        'rogue': 0xFFF569,
        'priest': 0xFFFFFF,
        'shaman': 0x0070DE,
        'mage': 0x69CCF0,
        'warlock': 0x9482C9,
        'monk': 0x00FF96,
        'druid': 0xFF7D0A,
        'dh': 0xA330C9,
        'dk': 0xC41F3B,
        'evoker': 0x33937F
    };
    
    const classColor = classColors[classId] || 0x69CCF0;
    
    // Create a placeholder for class model
    // In a real implementation, you would load actual 3D models
    // For now, we'll create a stylized emblem for each class
    
    function createClassEmblem(classId) {
        const group = new THREE.Group();
        
        // Base emblem - a disc with the class color
        const baseGeometry = new THREE.CircleGeometry(1.5, 32);
        const baseMaterial = new THREE.MeshStandardMaterial({
            color: classColor,
            metalness: 0.7,
            roughness: 0.3,
            emissive: classColor,
            emissiveIntensity: 0.2
        });
        
        const baseEmblem = new THREE.Mesh(baseGeometry, baseMaterial);
        group.add(baseEmblem);
        
        // Add a ring around the emblem
        const ringGeometry = new THREE.RingGeometry(1.5, 1.7, 32);
        const ringMaterial = new THREE.MeshStandardMaterial({
            color: 0xFFD700,
            metalness: 0.9,
            roughness: 0.1,
            side: THREE.DoubleSide
        });
        
        const ring = new THREE.Mesh(ringGeometry, ringMaterial);
        ring.position.z = 0.01;
        group.add(ring);
        
        // Add class-specific design elements
        switch(classId) {
            case 'warrior':
                addSymbol('⚔️', group);
                break;
            case 'paladin':
                addSymbol('✝️', group);
                break;
            case 'hunter':
                addSymbol('🏹', group);
                break;
            case 'rogue':
                addSymbol('🗡️', group);
                break;
            case 'priest':
                addSymbol('✨', group);
                break;
            case 'shaman':
                addSymbol('⚡', group);
                break;
            case 'mage':
                addSymbol('🔮', group);
                break;
            case 'warlock':
                addSymbol('🔥', group);
                break;
            case 'monk':
                addSymbol('☯️', group);
                break;
            case 'druid':
                addSymbol('🌿', group);
                break;
            case 'dh':
                addSymbol('👁️', group);
                break;
            case 'dk':
                addSymbol('❄️', group);
                break;
            case 'evoker':
                addSymbol('🐉', group);
                break;
            default:
                addSymbol('?', group);
        }
        
        return group;
    }
    
    function addSymbol(symbol, group) {
        // In a real implementation, you'd create actual 3D geometry for each class symbol
        // For this example, we'll create a simple plane with a color
        
        const symbolGeometry = new THREE.PlaneGeometry(1, 1);
        const symbolMaterial = new THREE.MeshBasicMaterial({
            color: 0xFFFFFF,
            transparent: true,
            opacity: 0.7
        });
        
        const symbolMesh = new THREE.Mesh(symbolGeometry, symbolMaterial);
        symbolMesh.position.z = 0.02;
        group.add(symbolMesh);
    }
    
    const classEmblem = createClassEmblem(classId);
    scene.add(classEmblem);
    
    // Add particle effects
    const particles = createParticles(classColor);
    scene.add(particles);
    
    // Handle responsive resizing
    window.addEventListener('resize', onWindowResize);
    
    function onWindowResize() {
        camera.aspect = container.clientWidth / container.clientHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(container.clientWidth, container.clientHeight);
    }
    
    // Animation loop
    const clock = new THREE.Clock();
    
    function animate() {
        requestAnimationFrame(animate);
        
        const time = clock.getElapsedTime();
        
        // Rotate the emblem
        classEmblem.rotation.y = Math.sin(time * 0.5) * 0.3;
        classEmblem.position.y = Math.sin(time) * 0.1;
        
        // Animate particles
        particles.rotation.y = time * 0.2;
        const positions = particles.geometry.attributes.position.array;
        
        for (let i = 0; i < positions.length; i += 3) {
            const i3 = i / 3;
            positions[i+1] += Math.sin(time + i3) * 0.005;
        }
        
        particles.geometry.attributes.position.needsUpdate = true;
        
        renderer.render(scene, camera);
    }
    
    animate();
}

/**
 * Create magical particles
 */
function createParticles(color = 0x69CCF0) {
    const particleCount = 500;
    const particles = new THREE.BufferGeometry();
    const positions = new Float32Array(particleCount * 3);
    const colors = new Float32Array(particleCount * 3);
    
    const colorObj = new THREE.Color(color);
    
    for (let i = 0; i < particleCount; i++) {
        // Position particles in a sphere
        const theta = Math.random() * Math.PI * 2;
        const phi = Math.acos(2 * Math.random() - 1);
        const radius = 2 + Math.random() * 2;
        
        positions[i * 3] = radius * Math.sin(phi) * Math.cos(theta);
        positions[i * 3 + 1] = radius * Math.sin(phi) * Math.sin(theta);
        positions[i * 3 + 2] = radius * Math.cos(phi);
        
        // Add some color variation
        colors[i * 3] = colorObj.r * (0.5 + Math.random() * 0.5);
        colors[i * 3 + 1] = colorObj.g * (0.5 + Math.random() * 0.5);
        colors[i * 3 + 2] = colorObj.b * (0.5 + Math.random() * 0.5);
    }
    
    particles.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    particles.setAttribute('color', new THREE.BufferAttribute(colors, 3));
    
    const particleMaterial = new THREE.PointsMaterial({
        size: 0.05,
        vertexColors: true,
        transparent: true,
        opacity: 0.7
    });
    
    return new THREE.Points(particles, particleMaterial);
}

// Make loadClassModel available globally
window.loadClassModel = initClassModel;