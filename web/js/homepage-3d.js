/**
 * ============================================================================
 * CINEMATIC 3D SCROLL ANIMATION & SEQUENTIAL TEXT POPUP ENGINE
 * ----------------------------------------------------------------------------
 * Technologies: Three.js (r128), GSAP (3.12+), GSAP ScrollTrigger
 * Story Flow:
 *   Scene 1: Container truck driving on highway under golden sunset
 *   Scene 2: Truck breakdown, pull over to shoulder, open hood, smoke, warning triangle
 *   Scene 3: Driver searches for mechanic on 3D smartphone roadside assistance app
 *   Scene 4: Mechanic arrives on service motorcycle with tool box
 *   Scene 5: Mechanic repairs truck under open hood, smoke clears
 *   Scene 6: Driver and mechanic thumbs-up, truck departs back onto highway
 *
 * Requirements:
 *   - 6 sequential sections in actual vertical page flow (Scene 1 -> 2 -> 3 -> 4 -> 5 -> 6)
 *   - Independent text popup animation: badge/label first, heading next, description next,
 *     image reveal next, buttons last.
 *   - Zero-Blue Orange & Charcoal automotive theme.
 * ============================================================================
 */

(function () {
    'use strict';

    // Global 3D variables
    let scene, camera, cameraTarget, renderer, clock;
    let truckGroup, hoodPivot, smokeParticles, wheels = [];
    let roadGroup, roadDividers = [], guardRails = [], streetLights = [];
    let hazardLights = [], headlightBeams = [];
    let smartphoneMesh, phoneCanvasTexture;
    let motorcycleGroup, mechanicFigure, driverFigure, warningTriangle, trafficCones = [];
    let bikeWheels = [];
    let driverArms = {}, mechanicArms = {};
    let scene6DepartTimer = null, isScene6Departed = false;
    let masterTimeline;
    let canvasContainer, canvasElement;
    let isDriving = true;
    let truckSpeed = 0.8;
    let smokeOpacity = 0;
    let hazardBlink = false;
    let mouse = { x: 0, y: 0, targetX: 0, targetY: 0 };
    let currentActiveIndex = 0;

    // Palette constants
    const COLOR_ORANGE = 0xF97316;
    const COLOR_DARK_ORANGE = 0xEA580C;
    const COLOR_CHARCOAL = 0x1F2937;
    const COLOR_DEEP_DARK = 0x111827;
    const COLOR_DARK_GRAY = 0x374151;
    const COLOR_LIGHT_GRAY = 0xF3F4F6;
    const COLOR_ROAD_ASPHALT = 0x1E242E;
    const COLOR_WHITE = 0xFFFFFF;
    const COLOR_RED = 0xDC2626;
    const COLOR_GREEN = 0x16A34A;
    const COLOR_WARM_SUN = 0xFF8C38;
    const COLOR_HEADLIGHT = 0xFFFBEB;

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    function init() {
        canvasContainer = document.querySelector('.cinematic-backdrop-fixed') || document.body;
        canvasElement = document.getElementById('three-canvas');

        if (!canvasElement || typeof THREE === 'undefined') {
            console.warn('[3D Engine] Three.js or canvas element not found. Running CSS text popups only.');
            setupTextPopups();
            setupInteractiveEvents();
            return;
        }

        setupThreeScene();
        buildEnvironment();
        buildTruck();
        buildWarningTriangleAndCones();
        build3DSmartphone();
        buildServiceMotorcycle();
        buildHumanFigures();
        setupLighting();
        setupMaster3DScrollTrigger();
        setupTextPopups();
        setupInteractiveEvents();
        animate();
    }

    // ------------------------------------------------------------------------
    // 1. SETUP THREE.JS SCENE, CAMERA & RENDERER
    // ------------------------------------------------------------------------
    function setupThreeScene() {
        scene = new THREE.Scene();
        scene.background = new THREE.Color(0x0C101A);
        scene.fog = new THREE.FogExp2(0x0C101A, 0.009);

        clock = new THREE.Clock();

        const width = window.innerWidth;
        const height = window.innerHeight;

        camera = new THREE.PerspectiveCamera(45, width / height, 0.2, 800);
        camera.position.set(14, 7, 24);
        cameraTarget = new THREE.Vector3(0, 3, 0);
        camera.lookAt(cameraTarget.x, cameraTarget.y, cameraTarget.z);

        renderer = new THREE.WebGLRenderer({
            canvas: canvasElement,
            antialias: true,
            alpha: false,
            powerPreference: 'high-performance'
        });

        renderer.setSize(width, height);
        renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
        renderer.shadowMap.enabled = true;
        renderer.shadowMap.type = THREE.PCFSoftShadowMap;
        if (THREE.ACESFilmicToneMapping) {
            renderer.toneMapping = THREE.ACESFilmicToneMapping;
            renderer.toneMappingExposure = 1.05;
        }
    }

    // ------------------------------------------------------------------------
    // 2. LIGHTING (SUNSET GOLDEN HOUR & AMBIENCE - STRICT ZERO BLUE)
    // ------------------------------------------------------------------------
    function setupLighting() {
        // Warm ambient light
        const ambientLight = new THREE.AmbientLight(0xFFE5D0, 0.65);
        scene.add(ambientLight);

        // Golden sunset sun (directional light casting shadows)
        const sunLight = new THREE.DirectionalLight(COLOR_WARM_SUN, 1.8);
        sunLight.position.set(35, 45, -30);
        sunLight.castShadow = true;
        sunLight.shadow.mapSize.width = 2048;
        sunLight.shadow.mapSize.height = 2048;
        sunLight.shadow.camera.near = 5;
        sunLight.shadow.camera.far = 180;
        sunLight.shadow.camera.left = -40;
        sunLight.shadow.camera.right = 40;
        sunLight.shadow.camera.top = 40;
        sunLight.shadow.camera.bottom = -40;
        sunLight.shadow.bias = -0.0005;
        scene.add(sunLight);

        // Warm rim light for metallic truck reflections
        const rimLight = new THREE.DirectionalLight(COLOR_DARK_ORANGE, 0.9);
        rimLight.position.set(-25, 20, 35);
        scene.add(rimLight);

        // Ground bounce warm fill
        const groundFill = new THREE.HemisphereLight(0xFDBA74, 0x1F2937, 0.5);
        scene.add(groundFill);
    }

    // ------------------------------------------------------------------------
    // 3. BUILD HIGHWAY ENVIRONMENT
    // ------------------------------------------------------------------------
    function buildEnvironment() {
        roadGroup = new THREE.Group();
        scene.add(roadGroup);

        // Main Asphalt Road
        const roadGeo = new THREE.PlaneGeometry(16, 500);
        const roadMat = new THREE.MeshStandardMaterial({
            color: COLOR_ROAD_ASPHALT,
            roughness: 0.85,
            metalness: 0.1
        });
        const roadMesh = new THREE.Mesh(roadGeo, roadMat);
        roadMesh.rotation.x = -Math.PI / 2;
        roadMesh.receiveShadow = true;
        roadGroup.add(roadMesh);

        // Road Shoulder Ground
        const groundGeo = new THREE.PlaneGeometry(240, 500);
        const groundMat = new THREE.MeshStandardMaterial({
            color: 0x141822,
            roughness: 0.95,
            metalness: 0.05
        });
        const groundMesh = new THREE.Mesh(groundGeo, groundMat);
        groundMesh.rotation.x = -Math.PI / 2;
        groundMesh.position.y = -0.05;
        groundMesh.receiveShadow = true;
        roadGroup.add(groundMesh);

        // Road Edge Lines
        const edgeLineGeo = new THREE.PlaneGeometry(0.3, 500);
        const edgeLineMat = new THREE.MeshBasicMaterial({ color: 0xE5E7EB });

        const leftEdge = new THREE.Mesh(edgeLineGeo, edgeLineMat);
        leftEdge.rotation.x = -Math.PI / 2;
        leftEdge.position.set(-7.5, 0.02, 0);
        roadGroup.add(leftEdge);

        const rightEdge = new THREE.Mesh(edgeLineGeo, edgeLineMat);
        rightEdge.rotation.x = -Math.PI / 2;
        rightEdge.position.set(7.5, 0.02, 0);
        roadGroup.add(rightEdge);

        // Dashed Lane Dividers (animated for driving motion)
        const dividerGeo = new THREE.PlaneGeometry(0.28, 4.5);
        const dividerMat = new THREE.MeshBasicMaterial({ color: 0xF3F4F6 });

        for (let z = -240; z <= 240; z += 9) {
            const divider = new THREE.Mesh(dividerGeo, dividerMat);
            divider.rotation.x = -Math.PI / 2;
            divider.position.set(0, 0.025, z);
            roadGroup.add(divider);
            roadDividers.push(divider);
        }

        // Guardrails
        const railGeo = new THREE.BoxGeometry(0.2, 0.7, 500);
        const railMat = new THREE.MeshStandardMaterial({ color: 0x6B7280, metalness: 0.6, roughness: 0.4 });

        const leftRail = new THREE.Mesh(railGeo, railMat);
        leftRail.position.set(-8.8, 0.8, 0);
        leftRail.castShadow = true;
        roadGroup.add(leftRail);

        const rightRail = new THREE.Mesh(railGeo, railMat);
        rightRail.position.set(8.8, 0.8, 0);
        rightRail.castShadow = true;
        roadGroup.add(rightRail);

        // Guardrail support posts
        const postGeo = new THREE.BoxGeometry(0.25, 1.2, 0.25);
        for (let z = -240; z <= 240; z += 12) {
            const p1 = new THREE.Mesh(postGeo, railMat);
            p1.position.set(-8.8, 0.6, z);
            roadGroup.add(p1);

            const p2 = new THREE.Mesh(postGeo, railMat);
            p2.position.set(8.8, 0.6, z);
            roadGroup.add(p2);
        }

        // Roadside Trees
        const trunkGeo = new THREE.CylinderGeometry(0.3, 0.4, 3, 6);
        const trunkMat = new THREE.MeshStandardMaterial({ color: 0x3E2723, roughness: 0.9 });
        const foliageGeo = new THREE.ConeGeometry(2.5, 5, 7);
        const foliageMat = new THREE.MeshStandardMaterial({ color: 0x1E3A2F, roughness: 0.85 });

        for (let i = 0; i < 36; i++) {
            const treeGroup = new THREE.Group();
            const trunk = new THREE.Mesh(trunkGeo, trunkMat);
            trunk.position.y = 1.5;
            trunk.castShadow = true;
            treeGroup.add(trunk);

            const foliage = new THREE.Mesh(foliageGeo, foliageMat);
            foliage.position.y = 4.5;
            foliage.castShadow = true;
            treeGroup.add(foliage);

            const side = i % 2 === 0 ? -1 : 1;
            const xOffset = side * (14 + Math.random() * 18);
            const zOffset = -220 + i * 13 + (Math.random() * 6 - 3);
            const scale = 0.85 + Math.random() * 0.5;

            treeGroup.position.set(xOffset, 0, zOffset);
            treeGroup.scale.set(scale, scale, scale);
            roadGroup.add(treeGroup);
        }

        // Distant Mountains
        const mountainGeo = new THREE.ConeGeometry(40, 28, 5);
        const mountainMat = new THREE.MeshStandardMaterial({ color: 0x111622, roughness: 0.95 });
        for (let m = 0; m < 8; m++) {
            const mountain = new THREE.Mesh(mountainGeo, mountainMat);
            mountain.position.set(-100 + m * 30, 8, -250);
            mountain.scale.set(1 + Math.random() * 0.5, 1 + Math.random() * 0.4, 1);
            roadGroup.add(mountain);
        }
    }

    // ------------------------------------------------------------------------
    // 4. CREATE CONTAINER TEXTURE CANVAS ("ROAD CARRIER")
    // ------------------------------------------------------------------------
    function createContainerTexture() {
        const canvas = document.createElement('canvas');
        canvas.width = 1024;
        canvas.height = 512;
        const ctx = canvas.getContext('2d');

        // Dark orange background
        ctx.fillStyle = '#C2410C';
        ctx.fillRect(0, 0, canvas.width, canvas.height);

        // Vertical corrugation stripes
        for (let x = 0; x < canvas.width; x += 16) {
            ctx.fillStyle = (x % 32 === 0) ? '#EA580C' : '#9A3412';
            ctx.fillRect(x, 0, 16, canvas.height);
        }

        // Top/bottom trim
        ctx.fillStyle = '#1F2937';
        ctx.fillRect(0, 0, canvas.width, 24);
        ctx.fillRect(0, canvas.height - 24, canvas.width, 24);

        // Center logo placard
        ctx.fillStyle = '#F97316';
        ctx.fillRect(160, 190, 704, 132);
        ctx.strokeStyle = '#FFFFFF';
        ctx.lineWidth = 6;
        ctx.strokeRect(160, 190, 704, 132);

        // Bold text matching reference: "ROAD CARRIER"
        ctx.fillStyle = '#FFFFFF';
        ctx.font = 'bold 64px "Arial Black", "Impact", sans-serif';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText('ROAD CARRIER', 512, 256);

        // Safety warning stripes
        ctx.fillStyle = '#FFFFFF';
        for (let s = 20; s < 140; s += 30) {
            ctx.beginPath();
            ctx.moveTo(s, 20);
            ctx.lineTo(s + 20, 20);
            ctx.lineTo(s - 10, canvas.height - 20);
            ctx.lineTo(s - 30, canvas.height - 20);
            ctx.fill();
        }

        const texture = new THREE.CanvasTexture(canvas);
        texture.wrapS = THREE.RepeatWrapping;
        texture.wrapT = THREE.RepeatWrapping;
        return texture;
    }

    // ------------------------------------------------------------------------
    // 5. BUILD 3D ORANGE CONTAINER TRUCK
    // ------------------------------------------------------------------------
    function buildTruck() {
        truckGroup = new THREE.Group();
        truckGroup.position.set(3.5, 0, 0);
        scene.add(truckGroup);

        const orangeMat = new THREE.MeshStandardMaterial({ color: COLOR_ORANGE, metalness: 0.25, roughness: 0.35 });
        const darkOrangeMat = new THREE.MeshStandardMaterial({ color: COLOR_DARK_ORANGE, metalness: 0.3, roughness: 0.4 });
        const charcoalMat = new THREE.MeshStandardMaterial({ color: COLOR_CHARCOAL, metalness: 0.4, roughness: 0.6 });
        const chromeMat = new THREE.MeshStandardMaterial({ color: 0xD1D5DB, metalness: 0.85, roughness: 0.2 });
        const glassMat = new THREE.MeshStandardMaterial({ color: 0x111827, metalness: 0.9, roughness: 0.1, transparent: true, opacity: 0.85 });

        // Heavy Chassis
        const chassis = new THREE.Mesh(new THREE.BoxGeometry(2.6, 0.45, 17), charcoalMat);
        chassis.position.set(0, 0.85, -1);
        chassis.castShadow = true;
        chassis.receiveShadow = true;
        truckGroup.add(chassis);

        // Cab Group
        const cabGroup = new THREE.Group();
        cabGroup.position.set(0, 0.9, 4.8);
        truckGroup.add(cabGroup);

        // Main Cab
        const cabMain = new THREE.Mesh(new THREE.BoxGeometry(2.55, 2.7, 3.2), orangeMat);
        cabMain.position.set(0, 1.45, 0);
        cabMain.castShadow = true;
        cabGroup.add(cabMain);

        // Windshield
        const windshield = new THREE.Mesh(new THREE.PlaneGeometry(2.35, 1.15), glassMat);
        windshield.position.set(0, 2.1, 1.62);
        windshield.rotation.x = -0.15;
        cabGroup.add(windshield);

        // Side Windows
        const leftWindow = new THREE.Mesh(new THREE.PlaneGeometry(1.6, 0.9), glassMat);
        leftWindow.rotation.y = Math.PI / 2;
        leftWindow.position.set(-1.29, 2.05, 0.2);
        cabGroup.add(leftWindow);

        const rightWindow = new THREE.Mesh(new THREE.PlaneGeometry(1.6, 0.9), glassMat);
        rightWindow.rotation.y = -Math.PI / 2;
        rightWindow.position.set(1.29, 2.05, 0.2);
        cabGroup.add(rightWindow);

        // Grille & Bumper
        const bumper = new THREE.Mesh(new THREE.BoxGeometry(2.6, 0.55, 0.5), charcoalMat);
        bumper.position.set(0, 0.35, 1.7);
        bumper.castShadow = true;
        cabGroup.add(bumper);

        const grille = new THREE.Mesh(new THREE.BoxGeometry(2.0, 0.9, 0.15), charcoalMat);
        grille.position.set(0, 1.1, 1.65);
        cabGroup.add(grille);

        for (let g = 0; g < 3; g++) {
            const slat = new THREE.Mesh(new THREE.BoxGeometry(1.9, 0.08, 0.06), chromeMat);
            slat.position.set(0, 0.85 + g * 0.25, 1.74);
            cabGroup.add(slat);
        }

        // Dual Headlights
        const headlightGeo = new THREE.BoxGeometry(0.45, 0.25, 0.1);
        const headlightMat = new THREE.MeshBasicMaterial({ color: COLOR_HEADLIGHT });

        const leftHeadlight = new THREE.Mesh(headlightGeo, headlightMat);
        leftHeadlight.position.set(-0.95, 0.45, 1.95);
        cabGroup.add(leftHeadlight);

        const rightHeadlight = new THREE.Mesh(headlightGeo, headlightMat);
        rightHeadlight.position.set(0.95, 0.45, 1.95);
        cabGroup.add(rightHeadlight);

        // Spotlights
        const leftSpot = new THREE.SpotLight(0xFFF7ED, 2.0, 50, Math.PI / 6, 0.4);
        leftSpot.position.set(-0.95, 1.2, 5.5);
        leftSpot.target.position.set(-0.95, 0, 25);
        scene.add(leftSpot);
        scene.add(leftSpot.target);
        headlightBeams.push(leftSpot);

        const rightSpot = new THREE.SpotLight(0xFFF7ED, 2.0, 50, Math.PI / 6, 0.4);
        rightSpot.position.set(0.95, 1.2, 5.5);
        rightSpot.target.position.set(0.95, 0, 25);
        scene.add(rightSpot);
        scene.add(rightSpot.target);
        headlightBeams.push(rightSpot);

        // Side Mirrors
        const leftMirror = new THREE.Mesh(new THREE.BoxGeometry(0.12, 0.5, 0.25), charcoalMat);
        leftMirror.position.set(-1.42, 2.1, 1.3);
        cabGroup.add(leftMirror);

        const rightMirror = new THREE.Mesh(new THREE.BoxGeometry(0.12, 0.5, 0.25), charcoalMat);
        rightMirror.position.set(1.42, 2.1, 1.3);
        cabGroup.add(rightMirror);

        // Roof Deflector
        const deflector = new THREE.Mesh(new THREE.BoxGeometry(2.35, 0.5, 1.8), orangeMat);
        deflector.position.set(0, 2.95, -0.4);
        deflector.rotation.x = -0.15;
        cabGroup.add(deflector);

        // Front Hinged Engine Hood
        hoodPivot = new THREE.Group();
        hoodPivot.position.set(0, 0.75, 1.62);
        cabGroup.add(hoodPivot);

        const hood = new THREE.Mesh(new THREE.BoxGeometry(2.3, 0.65, 0.85), orangeMat);
        hood.position.set(0, 0.35, -0.38);
        hood.castShadow = true;
        hoodPivot.add(hood);

        // Engine Bay inside
        const engineGroup = new THREE.Group();
        engineGroup.position.set(0, 0.9, 1.15);
        cabGroup.add(engineGroup);

        const engineBlock = new THREE.Mesh(
            new THREE.BoxGeometry(1.6, 0.75, 1.1),
            new THREE.MeshStandardMaterial({ color: 0x4B5563, metalness: 0.8, roughness: 0.3 })
        );
        engineGroup.add(engineBlock);

        const cylHead = new THREE.Mesh(
            new THREE.BoxGeometry(1.4, 0.25, 0.8),
            new THREE.MeshStandardMaterial({ color: COLOR_DARK_ORANGE, metalness: 0.5 })
        );
        cylHead.position.set(0, 0.45, 0);
        engineGroup.add(cylHead);

        const fan = new THREE.Mesh(
            new THREE.CylinderGeometry(0.35, 0.35, 0.08, 12),
            new THREE.MeshStandardMaterial({ color: 0x1F2937, metalness: 0.6 })
        );
        fan.rotation.x = Math.PI / 2;
        fan.position.set(0, 0.1, 0.6);
        engineGroup.add(fan);

        // Hazard Lights
        const hazardGeo = new THREE.SphereGeometry(0.12, 12, 12);
        const hazardMat = new THREE.MeshBasicMaterial({ color: COLOR_ORANGE });

        const hzLF = new THREE.Mesh(hazardGeo, hazardMat);
        hzLF.position.set(-1.25, 0.65, 1.85);
        cabGroup.add(hzLF);
        hazardLights.push(hzLF);

        const hzRF = new THREE.Mesh(hazardGeo, hazardMat);
        hzRF.position.set(1.25, 0.65, 1.85);
        cabGroup.add(hzRF);
        hazardLights.push(hzRF);

        const hazardPointLight = new THREE.PointLight(COLOR_ORANGE, 0, 15);
        hazardPointLight.position.set(0, 2.0, 6.0);
        scene.add(hazardPointLight);
        hazardLights.push(hazardPointLight);

        // Smoke Particle System
        buildEngineSmoke(engineGroup);

        // Shipping Container ("ROAD CARRIER")
        const containerGroup = new THREE.Group();
        containerGroup.position.set(0, 2.65, -3.2);
        truckGroup.add(containerGroup);

        const containerTexture = createContainerTexture();
        const containerMat = new THREE.MeshStandardMaterial({
            map: containerTexture,
            roughness: 0.45,
            metalness: 0.2
        });

        const container = new THREE.Mesh(new THREE.BoxGeometry(2.7, 3.4, 11.8), containerMat);
        container.castShadow = true;
        container.receiveShadow = true;
        containerGroup.add(container);

        // 10 Heavy Wheels
        const wheelPositions = [
            [-1.35, 0.55, 5.0], [1.35, 0.55, 5.0],
            [-1.35, 0.55, 2.4], [1.35, 0.55, 2.4],
            [-1.35, 0.55, 1.0], [1.35, 0.55, 1.0],
            [-1.35, 0.55, -6.2], [1.35, 0.55, -6.2],
            [-1.35, 0.55, -7.6], [1.35, 0.55, -7.6]
        ];

        const tireGeo = new THREE.CylinderGeometry(0.55, 0.55, 0.42, 20);
        const tireMat = new THREE.MeshStandardMaterial({ color: 0x111827, roughness: 0.9 });
        const rimGeo = new THREE.CylinderGeometry(0.32, 0.32, 0.44, 16);
        const rimMat = new THREE.MeshStandardMaterial({ color: 0x9CA3AF, metalness: 0.8, roughness: 0.3 });

        wheelPositions.forEach(pos => {
            const wheelUnit = new THREE.Group();
            wheelUnit.position.set(pos[0], pos[1], pos[2]);

            const tire = new THREE.Mesh(tireGeo, tireMat);
            tire.rotation.z = Math.PI / 2;
            tire.castShadow = true;
            wheelUnit.add(tire);

            const rim = new THREE.Mesh(rimGeo, rimMat);
            rim.rotation.z = Math.PI / 2;
            wheelUnit.add(rim);

            truckGroup.add(wheelUnit);
            wheels.push(wheelUnit);
        });
    }

    // ------------------------------------------------------------------------
    // 6. ENGINE SMOKE PARTICLES
    // ------------------------------------------------------------------------
    function buildEngineSmoke(parent) {
        const particleCount = 45;
        const geom = new THREE.BufferGeometry();
        const positions = new Float32Array(particleCount * 3);
        const scales = new Float32Array(particleCount);

        for (let i = 0; i < particleCount; i++) {
            positions[i * 3 + 0] = (Math.random() - 0.5) * 0.8;
            positions[i * 3 + 1] = Math.random() * 2.0;
            positions[i * 3 + 2] = (Math.random() - 0.5) * 0.8;
            scales[i] = Math.random() * 0.5 + 0.3;
        }

        geom.setAttribute('position', new THREE.BufferAttribute(positions, 3));
        geom.setAttribute('scale', new THREE.BufferAttribute(scales, 1));

        const canvas = document.createElement('canvas');
        canvas.width = 64;
        canvas.height = 64;
        const ctx = canvas.getContext('2d');
        const grad = ctx.createRadialGradient(32, 32, 0, 32, 32, 32);
        grad.addColorStop(0, 'rgba(230, 230, 230, 0.9)');
        grad.addColorStop(0.5, 'rgba(180, 180, 180, 0.4)');
        grad.addColorStop(1, 'rgba(100, 100, 100, 0)');
        ctx.fillStyle = grad;
        ctx.fillRect(0, 0, 64, 64);
        const smokeTex = new THREE.CanvasTexture(canvas);

        const mat = new THREE.PointsMaterial({
            size: 1.4,
            map: smokeTex,
            transparent: true,
            opacity: 0.0,
            depthWrite: false,
            color: 0xDDDDDD
        });

        smokeParticles = new THREE.Points(geom, mat);
        smokeParticles.position.set(0, 0.6, 0.2);
        parent.add(smokeParticles);
    }

    // ------------------------------------------------------------------------
    // 7. WARNING TRIANGLE & CONES
    // ------------------------------------------------------------------------
    function buildWarningTriangleAndCones() {
        warningTriangle = new THREE.Group();
        warningTriangle.position.set(3.5, 0, 14.5);
        warningTriangle.visible = false;
        scene.add(warningTriangle);

        const triangleShape = new THREE.Shape();
        triangleShape.moveTo(0, 1.1);
        triangleShape.lineTo(0.7, 0);
        triangleShape.lineTo(-0.7, 0);
        triangleShape.closePath();

        const hole = new THREE.Path();
        hole.moveTo(0, 0.85);
        hole.lineTo(0.48, 0.15);
        hole.lineTo(-0.48, 0.15);
        hole.closePath();
        triangleShape.holes.push(hole);

        const triGeo = new THREE.ExtrudeGeometry(triangleShape, { depth: 0.08, bevelEnabled: false });
        const triMat = new THREE.MeshStandardMaterial({
            color: COLOR_RED,
            emissive: 0x991B1B,
            emissiveIntensity: 0.4,
            roughness: 0.3
        });

        const triMesh = new THREE.Mesh(triGeo, triMat);
        triMesh.position.y = 0.1;
        triMesh.castShadow = true;
        warningTriangle.add(triMesh);

        const base = new THREE.Mesh(new THREE.BoxGeometry(0.8, 0.06, 0.4), new THREE.MeshStandardMaterial({ color: COLOR_CHARCOAL }));
        base.position.y = 0.03;
        warningTriangle.add(base);

        // Orange Traffic Cones
        const coneGeo = new THREE.ConeGeometry(0.3, 0.8, 16);
        const coneMat = new THREE.MeshStandardMaterial({ color: COLOR_ORANGE, roughness: 0.4 });
        const coneBaseGeo = new THREE.BoxGeometry(0.7, 0.06, 0.7);

        for (let c = 0; c < 3; c++) {
            const coneGroup = new THREE.Group();
            const cone = new THREE.Mesh(coneGeo, coneMat);
            cone.position.y = 0.4;
            cone.castShadow = true;
            coneGroup.add(cone);

            const cBase = new THREE.Mesh(coneBaseGeo, coneMat);
            cBase.position.y = 0.03;
            coneGroup.add(cBase);

            coneGroup.position.set(5.0 + c * 0.4, 0, 7.0 + c * 4.0);
            coneGroup.visible = false;
            scene.add(coneGroup);
            trafficCones.push(coneGroup);
        }
    }

    // ------------------------------------------------------------------------
    // 8. BUILD 3D SMARTPHONE (SCENE 3)
    // ------------------------------------------------------------------------
    function build3DSmartphone() {
        smartphoneMesh = new THREE.Group();
        smartphoneMesh.position.set(3.0, 4.5, 9.0);
        smartphoneMesh.rotation.set(-0.15, 0.3, 0);
        smartphoneMesh.scale.set(0.001, 0.001, 0.001);
        scene.add(smartphoneMesh);

        const body = new THREE.Mesh(
            new THREE.BoxGeometry(1.5, 2.9, 0.12),
            new THREE.MeshStandardMaterial({ color: COLOR_DEEP_DARK, metalness: 0.9, roughness: 0.2 })
        );
        body.castShadow = true;
        smartphoneMesh.add(body);

        const screenCanvas = document.createElement('canvas');
        screenCanvas.width = 512;
        screenCanvas.height = 960;
        const ctx = screenCanvas.getContext('2d');

        ctx.fillStyle = '#111827';
        ctx.fillRect(0, 0, 512, 960);

        ctx.fillStyle = '#1F2937';
        ctx.fillRect(0, 0, 512, 130);

        ctx.fillStyle = '#F97316';
        ctx.font = 'bold 26px "Plus Jakarta Sans", sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText('On Road Vehicle', 256, 52);
        ctx.font = 'bold 22px "Plus Jakarta Sans", sans-serif';
        ctx.fillStyle = '#FFFFFF';
        ctx.fillText('Breakdown Assistance', 256, 88);

        ctx.fillStyle = '#374151';
        ctx.roundRect ? ctx.roundRect(36, 150, 440, 64, 16) : ctx.rect(36, 150, 440, 64);
        ctx.fill();
        ctx.fillStyle = '#9CA3AF';
        ctx.font = '22px sans-serif';
        ctx.textAlign = 'left';
        ctx.fillText('🔍  Find Nearby Mechanics...', 60, 190);

        // Card 1: Karthik Auto Care
        ctx.fillStyle = '#1F2937';
        ctx.roundRect ? ctx.roundRect(36, 240, 440, 170, 20) : ctx.rect(36, 240, 440, 170);
        ctx.fill();
        ctx.strokeStyle = '#F97316';
        ctx.lineWidth = 3;
        ctx.stroke();

        ctx.fillStyle = '#EA580C';
        ctx.beginPath();
        ctx.arc(95, 325, 42, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = '#FFFFFF';
        ctx.font = 'bold 32px sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText('👨‍🔧', 95, 335);

        ctx.textAlign = 'left';
        ctx.fillStyle = '#FFFFFF';
        ctx.font = 'bold 26px "Plus Jakarta Sans", sans-serif';
        ctx.fillText('Karthik Auto Care', 160, 305);
        ctx.fillStyle = '#FACC15';
        ctx.font = 'bold 22px sans-serif';
        ctx.fillText('★ 4.8 (120+)', 160, 342);
        ctx.fillStyle = '#9CA3AF';
        ctx.fillText('📍 2.4 km away', 305, 342);

        // Card 2: Vignesh Motors
        ctx.fillStyle = '#1F2937';
        ctx.roundRect ? ctx.roundRect(36, 440, 440, 170, 20) : ctx.rect(36, 440, 440, 170);
        ctx.fill();
        ctx.strokeStyle = 'rgba(255, 255, 255, 0.15)';
        ctx.lineWidth = 2;
        ctx.stroke();

        ctx.fillStyle = '#374151';
        ctx.beginPath();
        ctx.arc(95, 525, 42, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = '#FFFFFF';
        ctx.fillText('🔧', 95, 535);

        ctx.textAlign = 'left';
        ctx.fillStyle = '#FFFFFF';
        ctx.font = 'bold 26px "Plus Jakarta Sans", sans-serif';
        ctx.fillText('Vignesh Motors', 160, 505);
        ctx.fillStyle = '#FACC15';
        ctx.font = 'bold 22px sans-serif';
        ctx.fillText('★ 4.6 (58+)', 160, 542);
        ctx.fillStyle = '#9CA3AF';
        ctx.fillText('📍 3.1 km away', 305, 542);

        // Request button
        ctx.fillStyle = '#F97316';
        ctx.roundRect ? ctx.roundRect(40, 780, 432, 84, 22) : ctx.rect(40, 780, 432, 84);
        ctx.fill();
        ctx.fillStyle = '#FFFFFF';
        ctx.font = 'bold 30px "Plus Jakarta Sans", sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText('Request Assistance', 256, 834);

        phoneCanvasTexture = new THREE.CanvasTexture(screenCanvas);
        const screenMesh = new THREE.Mesh(new THREE.PlaneGeometry(1.38, 2.76), new THREE.MeshBasicMaterial({ map: phoneCanvasTexture }));
        screenMesh.position.z = 0.065;
        smartphoneMesh.add(screenMesh);
    }

    // ------------------------------------------------------------------------
    // 9. SERVICE MOTORCYCLE (SCENE 4)
    // ------------------------------------------------------------------------
    function buildServiceMotorcycle() {
        motorcycleGroup = new THREE.Group();
        motorcycleGroup.position.set(7.2, 0, 32.0);
        motorcycleGroup.visible = false;
        scene.add(motorcycleGroup);

        const bikeOrangeMat = new THREE.MeshStandardMaterial({ color: COLOR_ORANGE, metalness: 0.5, roughness: 0.3 });
        const bikeDarkMat = new THREE.MeshStandardMaterial({ color: COLOR_CHARCOAL, metalness: 0.7, roughness: 0.4 });
        const bikeTireMat = new THREE.MeshStandardMaterial({ color: 0x111827, roughness: 0.9 });
        const chromeMat = new THREE.MeshStandardMaterial({ color: 0xE5E7EB, metalness: 0.9, roughness: 0.2 });

        const frame = new THREE.Mesh(new THREE.BoxGeometry(0.35, 0.7, 1.8), bikeDarkMat);
        frame.position.y = 0.75;
        frame.castShadow = true;
        motorcycleGroup.add(frame);

        const tank = new THREE.Mesh(new THREE.BoxGeometry(0.4, 0.35, 0.75), bikeOrangeMat);
        tank.position.set(0, 1.05, 0.1);
        tank.castShadow = true;
        motorcycleGroup.add(tank);

        const seat = new THREE.Mesh(new THREE.BoxGeometry(0.36, 0.12, 0.7), bikeDarkMat);
        seat.position.set(0, 0.98, -0.45);
        motorcycleGroup.add(seat);

        // Handlebars
        const handlebar = new THREE.Mesh(new THREE.BoxGeometry(0.85, 0.06, 0.06), bikeDarkMat);
        handlebar.position.set(0, 1.25, 0.45);
        motorcycleGroup.add(handlebar);

        // Bike Headlight
        const bikeHeadlight = new THREE.Mesh(new THREE.SphereGeometry(0.12, 12, 12), new THREE.MeshBasicMaterial({ color: 0xFFFBEB }));
        bikeHeadlight.position.set(0, 1.15, 0.9);
        motorcycleGroup.add(bikeHeadlight);

        // Bike Taillight
        const bikeTaillight = new THREE.Mesh(new THREE.BoxGeometry(0.18, 0.08, 0.05), new THREE.MeshBasicMaterial({ color: 0xEF4444 }));
        bikeTaillight.position.set(0, 1.0, -1.25);
        motorcycleGroup.add(bikeTaillight);

        // Front Wheel
        const frontWheelGroup = new THREE.Group();
        frontWheelGroup.position.set(0, 0.38, 0.9);
        const frontWheel = new THREE.Mesh(new THREE.CylinderGeometry(0.38, 0.38, 0.16, 16), bikeTireMat);
        frontWheel.rotation.z = Math.PI / 2;
        frontWheel.castShadow = true;
        frontWheelGroup.add(frontWheel);
        motorcycleGroup.add(frontWheelGroup);

        // Rear Wheel
        const rearWheelGroup = new THREE.Group();
        rearWheelGroup.position.set(0, 0.38, -0.9);
        const rearWheel = new THREE.Mesh(new THREE.CylinderGeometry(0.38, 0.38, 0.16, 16), bikeTireMat);
        rearWheel.rotation.z = Math.PI / 2;
        rearWheel.castShadow = true;
        rearWheelGroup.add(rearWheel);
        motorcycleGroup.add(rearWheelGroup);

        bikeWheels = [frontWheel, rearWheel];

        const toolBox = new THREE.Mesh(new THREE.BoxGeometry(0.65, 0.5, 0.55), new THREE.MeshStandardMaterial({ color: COLOR_DARK_ORANGE, metalness: 0.4, roughness: 0.4 }));
        toolBox.position.set(0, 1.05, -0.95);
        toolBox.castShadow = true;
        motorcycleGroup.add(toolBox);
    }

    // ------------------------------------------------------------------------
    // 10. STYLIZED DRIVER & MECHANIC FIGURES
    // ------------------------------------------------------------------------
    function buildHumanFigures() {
        const skinMat = new THREE.MeshStandardMaterial({ color: 0xD4A373, roughness: 0.6 });
        const vestMat = new THREE.MeshStandardMaterial({ color: COLOR_ORANGE, roughness: 0.5 });
        const pantsMat = new THREE.MeshStandardMaterial({ color: 0x1E293B, roughness: 0.8 });
        const hairMat = new THREE.MeshStandardMaterial({ color: 0x111827 });

        // Driver
        driverFigure = new THREE.Group();
        driverFigure.position.set(4.8, 0, 7.2);
        driverFigure.visible = false;
        scene.add(driverFigure);

        const torso = new THREE.Mesh(new THREE.BoxGeometry(0.55, 0.75, 0.3), vestMat);
        torso.position.y = 1.15;
        torso.castShadow = true;
        driverFigure.add(torso);

        const head = new THREE.Mesh(new THREE.SphereGeometry(0.2, 16, 16), skinMat);
        head.position.y = 1.7;
        head.castShadow = true;
        driverFigure.add(head);

        const cap = new THREE.Mesh(new THREE.CylinderGeometry(0.22, 0.22, 0.1, 12), hairMat);
        cap.position.y = 1.84;
        driverFigure.add(cap);

        const legs = new THREE.Mesh(new THREE.BoxGeometry(0.46, 0.8, 0.25), pantsMat);
        legs.position.y = 0.4;
        legs.castShadow = true;
        driverFigure.add(legs);

        // Driver arms
        const driverLeftArm = new THREE.Mesh(new THREE.BoxGeometry(0.14, 0.55, 0.14), vestMat);
        driverLeftArm.position.set(-0.35, 1.15, 0);
        driverFigure.add(driverLeftArm);

        const driverRightArm = new THREE.Mesh(new THREE.BoxGeometry(0.14, 0.55, 0.14), vestMat);
        driverRightArm.position.set(0.35, 1.15, 0);
        driverFigure.add(driverRightArm);
        driverArms = { left: driverLeftArm, right: driverRightArm };

        // Mechanic
        mechanicFigure = new THREE.Group();
        mechanicFigure.position.set(5.8, 0, 7.2);
        mechanicFigure.visible = false;
        scene.add(mechanicFigure);

        const uniformMat = new THREE.MeshStandardMaterial({ color: COLOR_CHARCOAL, roughness: 0.6 });
        const mechVestMat = new THREE.MeshStandardMaterial({ color: COLOR_DARK_ORANGE, roughness: 0.5 });

        const mechTorso = new THREE.Mesh(new THREE.BoxGeometry(0.58, 0.78, 0.32), mechVestMat);
        mechTorso.position.y = 1.15;
        mechTorso.castShadow = true;
        mechanicFigure.add(mechTorso);

        const mechHead = new THREE.Mesh(new THREE.SphereGeometry(0.2, 16, 16), skinMat);
        mechHead.position.y = 1.7;
        mechHead.castShadow = true;
        mechanicFigure.add(mechHead);

        const mechCap = new THREE.Mesh(new THREE.CylinderGeometry(0.22, 0.22, 0.1, 12), uniformMat);
        mechCap.position.y = 1.84;
        mechanicFigure.add(mechCap);

        const mechLegs = new THREE.Mesh(new THREE.BoxGeometry(0.48, 0.8, 0.25), uniformMat);
        mechLegs.position.y = 0.4;
        mechLegs.castShadow = true;
        mechanicFigure.add(mechLegs);

        // Mechanic arms
        const mechLeftArm = new THREE.Mesh(new THREE.BoxGeometry(0.14, 0.55, 0.14), mechVestMat);
        mechLeftArm.position.set(-0.36, 1.15, 0);
        mechanicFigure.add(mechLeftArm);

        const mechRightArm = new THREE.Mesh(new THREE.BoxGeometry(0.14, 0.55, 0.14), mechVestMat);
        mechRightArm.position.set(0.36, 1.15, 0);
        mechanicFigure.add(mechRightArm);
        mechanicArms = { left: mechLeftArm, right: mechRightArm };

        const wrench = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.45, 0.05), new THREE.MeshStandardMaterial({ color: 0xD1D5DB, metalness: 0.85 }));
        wrench.position.set(0.38, 1.0, 0.2);
        wrench.rotation.z = -0.4;
        mechanicFigure.add(wrench);
    }

    // ------------------------------------------------------------------------
    // 11. MASTER 3D SCROLL TRIGGER (DRIVES 3D WORLD ACROSS ALL 6 VERTICAL SECTIONS)
    // ------------------------------------------------------------------------
    function setupMaster3DScrollTrigger() {
        if (typeof gsap === 'undefined' || typeof ScrollTrigger === 'undefined') return;

        gsap.registerPlugin(ScrollTrigger);

        const storyTrack = document.querySelector('.story-flow-track');
        if (!storyTrack) return;

        // Master Scrub Timeline orchestrating camera and 3D actors to match alternating layout:
        // Scene 1: Truck cruising on LEFT (Scroll 0.0 - 0.20)
        // Scene 2: Truck breakdown on RIGHT (Scroll 0.20 - 0.40)
        // Scene 3: Mobile search on LEFT (Scroll 0.40 - 0.60)
        // Scene 4: Mechanic arrival on RIGHT (Scroll 0.60 - 0.80)
        // Scene 5: On-site repair on LEFT (Scroll 0.80 - 0.92)
        // Scene 6: Back on road / departure on RIGHT (Scroll 0.92 - 1.00)
        masterTimeline = gsap.timeline({
            scrollTrigger: {
                trigger: storyTrack,
                start: 'top top',
                end: 'bottom bottom',
                scrub: 1.2,
                onUpdate: (self) => {
                    handleScrollProgress(self.progress);
                }
            }
        });

        // --- Transition 1 -> 2 (Time 0 to 2): Truck pulls over & breaks down on the RIGHT ---
        masterTimeline
            .to(camera.position, { x: -14, y: 6.5, z: 22, ease: 'power1.inOut', duration: 2.0 }, 0)
            .to(cameraTarget, { x: 0, y: 3.0, z: 0, ease: 'power1.inOut', duration: 2.0 }, 0)
            .to(truckGroup.position, { x: -3.5, z: 0, ease: 'power2.out', duration: 2.0 }, 0)
            .to(hoodPivot.rotation, { x: -0.85, ease: 'power2.out', duration: 1.4 }, 0.8)
            .to(warningTriangle.position, { x: -3.5, z: 14.5, duration: 1.0 }, 1.0)
            .to(driverFigure.position, { x: -2.0, z: 7.5, duration: 1.0 }, 1.0);

        // --- Transition 2 -> 3 (Time 2 to 4): Driver searches for help on smartphone on the LEFT ---
        masterTimeline
            .to(camera.position, { x: 14, y: 6.0, z: 20, ease: 'power1.inOut', duration: 2.0 }, 2.0)
            .to(cameraTarget, { x: 0, y: 3.2, z: 4.0, ease: 'power1.inOut', duration: 2.0 }, 2.0)
            .to(truckGroup.position, { x: 3.5, z: 0, ease: 'power2.out', duration: 2.0 }, 2.0)
            .to(driverFigure.position, { x: 2.0, z: 8.5, duration: 1.6 }, 2.2)
            .to(smartphoneMesh.position, { x: 3.5, y: 4.2, z: 10.0, duration: 1.8 }, 2.2)
            .to(smartphoneMesh.scale, { x: 1.15, y: 1.15, z: 1.15, ease: 'back.out(1.5)', duration: 1.8 }, 2.2);

        // --- Transition 3 -> 4 (Time 4 to 6): Rapid motorcycle & mechanic arrive on the RIGHT ---
        masterTimeline
            .to(smartphoneMesh.scale, { x: 0.001, y: 0.001, z: 0.001, ease: 'power2.in', duration: 1.2 }, 4.0)
            .to(camera.position, { x: -14, y: 6.5, z: 22, ease: 'power1.inOut', duration: 2.0 }, 4.0)
            .to(cameraTarget, { x: 0, y: 3.2, z: 4.0, ease: 'power1.inOut', duration: 2.0 }, 4.0)
            .to(truckGroup.position, { x: -3.5, z: 0, ease: 'power2.out', duration: 2.0 }, 4.0)
            .to(motorcycleGroup.position, { x: -6.5, z: 8.5, ease: 'power2.out', duration: 2.0 }, 4.0)
            .to(mechanicFigure.position, { x: -4.8, z: 8.0, duration: 1.8 }, 4.2);

        // --- Transition 4 -> 5 (Time 6 to 8): Mechanic repairs truck engine under open hood on the LEFT ---
        masterTimeline
            .to(camera.position, { x: 12, y: 5.0, z: 18, ease: 'power1.inOut', duration: 2.0 }, 6.0)
            .to(cameraTarget, { x: 0, y: 2.8, z: 4.0, ease: 'power1.inOut', duration: 2.0 }, 6.0)
            .to(truckGroup.position, { x: 3.5, z: 0, ease: 'power2.out', duration: 2.0 }, 6.0)
            .to(mechanicFigure.position, { x: 2.5, z: 6.2, duration: 1.8 }, 6.2)
            .to(mechanicFigure.rotation, { y: -0.6, duration: 1.5 }, 6.2)
            .to(driverFigure.position, { x: 4.5, z: 6.5, duration: 1.8 }, 6.2);

        // --- Transition 5 -> 6 (Time 8 to 10):
        // 8.0 - 8.5: Hood closes, driver & mechanic celebrate repair (the scene in user image)
        // 8.5 - 9.1: Driver walks to truck and enters cab; mechanic walks to motorcycle and mounts seat
        // 9.1 - 10.0: Driver departs with the truck; mechanic departs with his bike down the highway
        masterTimeline
            // Phase A: Hood closes & Camera frames Scene 6 celebration (8.0 - 8.5)
            .to(hoodPivot.rotation, { x: 0, ease: 'power2.inOut', duration: 0.8 }, 8.0)
            .to(camera.position, { x: -14, y: 7.5, z: 24, ease: 'power2.inOut', duration: 1.0 }, 8.0)
            .to(cameraTarget, { x: 0, y: 3.0, z: 0, ease: 'power2.inOut', duration: 1.0 }, 8.0)
            .to(truckGroup.position, { x: -3.5, y: 0, z: 0, ease: 'power1.out', duration: 0.8 }, 8.0)
            .to(motorcycleGroup.position, { x: -6.5, y: 0, z: 8.5, ease: 'power1.out', duration: 0.8 }, 8.0)
            .to(driverFigure.position, { x: -2.0, y: 0, z: 8.0, duration: 0.8 }, 8.0)
            .to(driverFigure.rotation, { x: 0, y: 0, z: 0, duration: 0.6 }, 8.0)
            .to(mechanicFigure.position, { x: -4.0, y: 0, z: 8.0, duration: 0.8 }, 8.0)
            .to(mechanicFigure.rotation, { x: 0, y: 0, z: 0, duration: 0.6 }, 8.0)

            // Phase B: Heading to their vehicles (8.5 - 9.1)
            // 1. Driver turns towards truck door, walks over, and climbs into the driver cabin
            .to(driverFigure.rotation, { y: -1.2, duration: 0.25 }, 8.5)
            .to(driverFigure.position, { x: -2.85, z: 4.8, duration: 0.4 }, 8.6)
            .to(driverFigure.position, { y: 1.35, duration: 0.25 }, 8.9)
            .to(driverFigure.rotation, { x: 0, y: 0, z: 0, duration: 0.2 }, 8.95)

            // 2. Mechanic turns towards motorcycle, walks over, and sits on the bike holding handlebars
            .to(mechanicFigure.rotation, { y: 1.2, duration: 0.25 }, 8.5)
            .to(mechanicFigure.position, { x: -6.5, z: 8.05, duration: 0.4 }, 8.6)
            .to(mechanicFigure.position, { y: 0.48, duration: 0.25 }, 8.9)
            .to(mechanicFigure.rotation, { x: -0.22, y: 0, z: 0, duration: 0.2 }, 8.95)

            // Phase C: Both Depart Together Down the Highway (9.1 - 10.0)
            // 1. Truck accelerates forward carrying the driver inside
            .to(truckGroup.position, { z: 58.0, ease: 'power1.in', duration: 0.9 }, 9.1)
            .to(driverFigure.position, { z: 62.8, ease: 'power1.in', duration: 0.9 }, 9.1)

            // 2. Motorcycle accelerates forward alongside the truck with the mechanic riding on it
            .to(motorcycleGroup.position, { z: 64.0, ease: 'power1.in', duration: 0.9 }, 9.1)
            .to(mechanicFigure.position, { z: 63.55, ease: 'power1.in', duration: 0.9 }, 9.1)

            // Camera pulls back and tracks both vehicles cruising together down the highway
            .to(cameraTarget, { x: -4.5, y: 3.5, z: 28.0, ease: 'power1.inOut', duration: 0.9 }, 9.1)
            .to(camera.position, { x: -16.0, y: 8.0, z: 28.0, ease: 'power1.inOut', duration: 0.9 }, 9.1);
    }

    // ------------------------------------------------------------------------
    // 12. INDEPENDENT TEXT POPUP & STAGGER ANIMATIONS (EVERY SCENE SECTION)
    // ------------------------------------------------------------------------
    function setupTextPopups() {
        if (typeof gsap === 'undefined' || typeof ScrollTrigger === 'undefined') {
            console.warn('[Text Popups] GSAP not available. Content remains visible via CSS.');
            return;
        }

        gsap.registerPlugin(ScrollTrigger);

        const sections = document.querySelectorAll('.story-scene-section');
        const trackerItems = document.querySelectorAll('.tracker-item');
        const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

        sections.forEach((section, index) => {
            const content = section.querySelector('.story-scene-content');
            if (!content) return;

            const numBadge = content.querySelector('.scene-num-badge');
            const tag = content.querySelector('.scene-tag');
            const heading = content.querySelector('.story-heading');
            const subtitle = content.querySelector('.story-subtitle');
            const buttons = content.querySelectorAll('.btn-scene-primary, .btn-scene-secondary');

            if (prefersReducedMotion) {
                return;
            }

            // Alternating zigzag direction for text entrance on desktop, purely vertical on mobile (< 768px):
            const isMobileScreen = (window.innerWidth < 768);
            const isTextRight = section.classList.contains('scene-layout-odd') || section.classList.contains('scene-text-right') || (index % 2 === 0);
            const xOffset = isMobileScreen ? 0 : (isTextRight ? 40 : -40);

            // CRITICAL: Animate ONLY the individual text elements.
            // Do NOT animate section, container, or parent content div!
            if (numBadge) gsap.set(numBadge, { opacity: 0, x: xOffset * 0.8, y: 16 });
            if (tag) gsap.set(tag, { opacity: 0, x: xOffset * 0.6, y: 14 });
            if (heading) gsap.set(heading, { opacity: 0, x: xOffset, y: 22, scale: 0.96 });
            if (subtitle) gsap.set(subtitle, { opacity: 0, x: xOffset * 0.8, y: 16 });
            if (buttons.length) gsap.set(buttons, { opacity: 0, x: xOffset * 0.6, y: 14 });

            // Staggered popup timeline for child text elements only with required timing:
            // Scene number: 0.1s | Scene label: 0.2s | Heading: 0.35s | Description: 0.5s | Buttons: 0.7s
            const popupTl = gsap.timeline({ paused: true });

            // 1. Scene Number (Fade in, slight upward movement)
            if (numBadge) {
                popupTl.to(numBadge, {
                    opacity: 1,
                    x: 0,
                    y: 0,
                    duration: 0.45,
                    ease: 'power2.out'
                }, 0.1);
            }

            // 2. Scene Label (Fade in, slight upward movement, small stagger after number)
            if (tag) {
                popupTl.to(tag, {
                    opacity: 1,
                    x: 0,
                    y: 0,
                    duration: 0.45,
                    ease: 'power2.out'
                }, 0.2);
            }

            // 3. Main Heading (Popup animation, fade in, slight upward movement, scale ~0.96 to 1)
            if (heading) {
                popupTl.to(heading, {
                    opacity: 1,
                    x: 0,
                    y: 0,
                    scale: 1,
                    duration: 0.55,
                    ease: 'power2.out'
                }, 0.35);
            }

            // 4. Description (Fade in, slight upward movement, staggered after heading)
            if (subtitle) {
                popupTl.to(subtitle, {
                    opacity: 1,
                    x: 0,
                    y: 0,
                    duration: 0.55,
                    ease: 'power2.out'
                }, 0.5);
            }

            // 5. CTA Buttons (Animate each button separately with small stagger delay, stationary after)
            if (buttons.length) {
                popupTl.to(buttons, {
                    opacity: 1,
                    x: 0,
                    y: 0,
                    stagger: 0.12,
                    duration: 0.5,
                    ease: 'power2.out'
                }, 0.7);
            }

            // Trigger text animation when section enters viewport
            ScrollTrigger.create({
                trigger: section,
                start: index === 0 ? 'top 90%' : 'top 70%',
                onEnter: () => {
                    popupTl.play();
                    updateTracker(index, trackerItems);
                    updateSceneActors(index);
                },
                onEnterBack: () => {
                    popupTl.play();
                    updateTracker(index, trackerItems);
                    updateSceneActors(index);
                }
            });
        });
    }

    // Update active tracker dot and label
    function updateTracker(activeIndex, trackerItems) {
        if (!trackerItems) return;
        trackerItems.forEach((item, idx) => {
            if (idx === activeIndex) {
                item.classList.add('active');
            } else {
                item.classList.remove('active');
            }
        });
    }

    // Update 3D scene props according to active scene
    function updateSceneActors(activeIndex) {
        currentActiveIndex = activeIndex;

        if (activeIndex === 0) {
            isDriving = true;
            truckSpeed = 1.0;
            smokeOpacity = 0.0;
            hazardBlink = false;
            if (warningTriangle) warningTriangle.visible = false;
            trafficCones.forEach(c => c.visible = false);
            if (driverFigure) driverFigure.visible = false;
            if (mechanicFigure) mechanicFigure.visible = false;
            if (motorcycleGroup) motorcycleGroup.visible = false;
        } else if (activeIndex === 1) {
            isDriving = false;
            truckSpeed = 0.0;
            smokeOpacity = 0.85;
            hazardBlink = true;
            if (warningTriangle) warningTriangle.visible = true;
            trafficCones.forEach(c => c.visible = true);
            if (driverFigure) driverFigure.visible = true;
            if (mechanicFigure) mechanicFigure.visible = false;
            if (motorcycleGroup) motorcycleGroup.visible = false;
        } else if (activeIndex === 2) {
            isDriving = false;
            truckSpeed = 0.0;
            smokeOpacity = 0.55;
            hazardBlink = true;
            if (warningTriangle) warningTriangle.visible = true;
            trafficCones.forEach(c => c.visible = true);
            if (driverFigure) driverFigure.visible = true;
            if (mechanicFigure) mechanicFigure.visible = false;
            if (motorcycleGroup) motorcycleGroup.visible = false;
        } else if (activeIndex === 3) {
            isDriving = false;
            truckSpeed = 0.0;
            smokeOpacity = 0.35;
            hazardBlink = true;
            if (warningTriangle) warningTriangle.visible = true;
            trafficCones.forEach(c => c.visible = true);
            if (driverFigure) driverFigure.visible = true;
            if (mechanicFigure) mechanicFigure.visible = true;
            if (motorcycleGroup) motorcycleGroup.visible = true;
        } else if (activeIndex === 4) {
            isDriving = false;
            truckSpeed = 0.0;
            smokeOpacity = 0.05;
            hazardBlink = true;
            if (warningTriangle) warningTriangle.visible = true;
            trafficCones.forEach(c => c.visible = true);
            if (driverFigure) driverFigure.visible = true;
            if (mechanicFigure) mechanicFigure.visible = true;
            if (motorcycleGroup) motorcycleGroup.visible = true;
        } else {
            isDriving = false;
            truckSpeed = 0.0;
            smokeOpacity = 0.0;
            hazardBlink = false;
            if (warningTriangle) warningTriangle.visible = false;
            trafficCones.forEach(c => c.visible = false);
            if (driverFigure) driverFigure.visible = true;
            if (mechanicFigure) mechanicFigure.visible = true;
            if (motorcycleGroup) motorcycleGroup.visible = true;
            checkScene6IdleDeparture();
        }

        if (smokeParticles && smokeParticles.material) {
            smokeParticles.material.opacity = smokeOpacity;
        }
    }

    // Scene 6 automated departure when user pauses on the scene
    function checkScene6IdleDeparture() {
        if (scene6DepartTimer) {
            clearTimeout(scene6DepartTimer);
            scene6DepartTimer = null;
        }
        isScene6Departed = false;

        if (currentActiveIndex === 5) {
            scene6DepartTimer = setTimeout(() => {
                if (currentActiveIndex === 5 && !isScene6Departed) {
                    playScene6BoardAndDepart();
                }
            }, 2200);
        }
    }

    let scene6DepartTl = null;
    function playScene6BoardAndDepart() {
        if (typeof gsap === 'undefined') return;
        isScene6Departed = true;

        if (scene6DepartTl) scene6DepartTl.kill();
        scene6DepartTl = gsap.timeline({
            onStart: () => {
                // start driving animation
                isDriving = true;
                truckSpeed = 1.0;
            }
        });

        scene6DepartTl
            // Driver turns & enters cab
            .to(driverFigure.rotation, { y: -1.2, duration: 0.35, ease: 'power1.inOut' }, 0)
            .to(driverFigure.position, { x: -2.85, z: 4.8, duration: 0.6, ease: 'power1.inOut' }, 0.2)
            .to(driverFigure.position, { y: 1.35, duration: 0.35, ease: 'power1.out' }, 0.7)
            .to(driverFigure.rotation, { x: 0, y: 0, z: 0, duration: 0.2 }, 0.85)

            // Mechanic turns & mounts motorcycle
            .to(mechanicFigure.rotation, { y: 1.2, duration: 0.35, ease: 'power1.inOut' }, 0)
            .to(mechanicFigure.position, { x: -6.5, z: 8.05, duration: 0.6, ease: 'power1.inOut' }, 0.2)
            .to(mechanicFigure.position, { y: 0.48, duration: 0.35, ease: 'power1.out' }, 0.7)
            .to(mechanicFigure.rotation, { x: -0.22, y: 0, z: 0, duration: 0.2 }, 0.85)

            // Both vehicles accelerate forward down the highway together
            .to(truckGroup.position, { z: "+=50.0", duration: 2.2, ease: 'power1.in' }, 1.2)
            .to(driverFigure.position, { z: "+=50.0", duration: 2.2, ease: 'power1.in' }, 1.2)
            .to(motorcycleGroup.position, { z: "+=54.0", duration: 2.2, ease: 'power1.in' }, 1.2)
            .to(mechanicFigure.position, { z: "+=54.0", duration: 2.2, ease: 'power1.in' }, 1.2)
            .to(cameraTarget, { z: "+=25.0", duration: 2.2, ease: 'power1.inOut' }, 1.2);
    }

    // Scroll progress handler
    function handleScrollProgress(progress) {
        let activeIdx = 0;
        if (progress < 0.18) activeIdx = 0;
        else if (progress < 0.36) activeIdx = 1;
        else if (progress < 0.54) activeIdx = 2;
        else if (progress < 0.72) activeIdx = 3;
        else if (progress < 0.88) activeIdx = 4;
        else activeIdx = 5;

        // In Scene 6: driving state activates as departure progresses (progress >= 0.91)
        if (activeIdx === 5) {
            if (progress >= 0.91) {
                isDriving = true;
                truckSpeed = 1.3;
            } else if (!isScene6Departed) {
                isDriving = false;
                truckSpeed = 0.0;
            }
        }

        if (activeIdx !== currentActiveIndex) {
            if (activeIdx !== 5) {
                if (scene6DepartTimer) {
                    clearTimeout(scene6DepartTimer);
                    scene6DepartTimer = null;
                }
                if (scene6DepartTl) {
                    scene6DepartTl.kill();
                    scene6DepartTl = null;
                }
                isScene6Departed = false;
            }
            updateSceneActors(activeIdx);
            const trackerItems = document.querySelectorAll('.tracker-item');
            updateTracker(activeIdx, trackerItems);
        }
    }

    // ------------------------------------------------------------------------
    // 13. INTERACTIVE EVENTS (SMOOTH SCROLL, TRACKER, RESIZE)
    // ------------------------------------------------------------------------
    function setupInteractiveEvents() {
        // Mouse parallax
        window.addEventListener('mousemove', (e) => {
            mouse.targetX = (e.clientX / window.innerWidth - 0.5) * 1.5;
            mouse.targetY = (e.clientY / window.innerHeight - 0.5) * 1.0;
        });

        // Clickable vertical tracker dots -> Smooth scroll to section in page flow
        const trackerItems = document.querySelectorAll('.tracker-item');
        trackerItems.forEach((item) => {
            item.addEventListener('click', (e) => {
                e.preventDefault();
                const targetSelector = item.getAttribute('data-target');
                if (!targetSelector) return;
                const targetElement = document.querySelector(targetSelector);
                if (targetElement) {
                    targetElement.scrollIntoView({
                        behavior: 'smooth',
                        block: 'center'
                    });
                }
            });
        });

        // Window resize
        window.addEventListener('resize', onWindowResize);

        // Sticky header styling
        const siteHeader = document.querySelector('.site-header');
        window.addEventListener('scroll', () => {
            if (window.scrollY > 40) {
                siteHeader && siteHeader.classList.add('scrolled');
            } else {
                siteHeader && siteHeader.classList.remove('scrolled');
            }
        });

        // Mobile drawer menu toggle
        const mobileMenuBtn = document.getElementById('mobileMenuBtn');
        const mobileDrawer = document.getElementById('mobileDrawer');
        if (mobileMenuBtn && mobileDrawer) {
            mobileMenuBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                mobileDrawer.classList.toggle('open');
            });

            document.addEventListener('click', (e) => {
                if (!mobileDrawer.contains(e.target) && e.target !== mobileMenuBtn) {
                    mobileDrawer.classList.remove('open');
                }
            });

            mobileDrawer.querySelectorAll('a').forEach((link) => {
                link.addEventListener('click', () => {
                    mobileDrawer.classList.remove('open');
                });
            });
        }
    }

    function onWindowResize() {
        if (!camera || !renderer) return;

        const width = window.innerWidth;
        const height = window.innerHeight;

        camera.aspect = width / height;
        camera.updateProjectionMatrix();

        renderer.setSize(width, height);
        renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    }

    // ------------------------------------------------------------------------
    // 14. 3D RENDER LOOP
    // ------------------------------------------------------------------------
    function animate() {
        requestAnimationFrame(animate);

        const delta = clock.getDelta();
        const elapsedTime = clock.getElapsedTime();

        // Mouse parallax
        mouse.x += (mouse.targetX - mouse.x) * 0.05;
        mouse.y += (mouse.targetY - mouse.y) * 0.05;

        if (camera && cameraTarget) {
            camera.position.x += mouse.x * 0.02;
            camera.position.y += -mouse.y * 0.02;
            camera.lookAt(cameraTarget.x, cameraTarget.y, cameraTarget.z);
        }

        // Road divider scroll & wheel rotation during driving
        if (isDriving) {
            const moveStep = truckSpeed * 32 * delta;

            roadDividers.forEach((div) => {
                div.position.z += moveStep;
                if (div.position.z > 240) {
                    div.position.z -= 480;
                }
            });

            wheels.forEach((w) => {
                w.children.forEach(c => c.rotation.x += truckSpeed * 12 * delta);
            });

            if (bikeWheels && bikeWheels.length) {
                bikeWheels.forEach((bw) => {
                    bw.rotation.x += truckSpeed * 18 * delta;
                });
            }
        }

        // Smoke particles billowing
        if (smokeParticles && smokeParticles.geometry && smokeOpacity > 0.01) {
            const positions = smokeParticles.geometry.attributes.position.array;
            for (let i = 0; i < positions.length / 3; i++) {
                positions[i * 3 + 1] += (0.8 + Math.random() * 0.4) * delta;
                positions[i * 3 + 0] += (Math.sin(elapsedTime * 3 + i) * 0.3) * delta;

                if (positions[i * 3 + 1] > 2.8) {
                    positions[i * 3 + 1] = 0.2;
                    positions[i * 3 + 0] = (Math.random() - 0.5) * 0.6;
                }
            }
            smokeParticles.geometry.attributes.position.needsUpdate = true;
        }

        // Flashing amber hazard lights
        if (hazardBlink) {
            const flash = Math.sin(elapsedTime * 7) > 0;
            hazardLights.forEach((hz) => {
                if (hz.isPointLight) {
                    hz.intensity = flash ? 3.0 : 0;
                } else if (hz.material) {
                    hz.material.color.setHex(flash ? COLOR_ORANGE : 0x442200);
                }
            });
        } else {
            hazardLights.forEach((hz) => {
                if (hz.isPointLight) {
                    hz.intensity = 0;
                } else if (hz.material) {
                    hz.material.color.setHex(0x442200);
                }
            });
        }

        // Floating hover for 3D Smartphone
        if (smartphoneMesh && smartphoneMesh.scale.x > 0.1) {
            smartphoneMesh.position.y = 4.2 + Math.sin(elapsedTime * 2) * 0.1;
            smartphoneMesh.rotation.y = 0.3 + Math.cos(elapsedTime * 1.5) * 0.08;
        }

        // Render scene
        if (renderer && scene && camera) {
            renderer.render(scene, camera);
        }
    }

})();
