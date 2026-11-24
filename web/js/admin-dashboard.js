/**
 * On Road Vehicle Breakdown Assistance - Admin Dashboard JS
 * Strict Zero-Blue Automotive Palette
 */

document.addEventListener('DOMContentLoaded', function () {
    initSidebarToggle();
    initHeroCarousel();
    initServiceRequestsChart();
    initSearchFilter();
    initTimeFilter();
});

/* ==========================================================================
   1. SIDEBAR TOGGLE & RESPONSIVENESS
   ========================================================================== */
function initSidebarToggle() {
    // Delegated to Master Universal Responsive Engine (app-responsive.js)
    if (window.toggleAppSidebar) return;
}

/* ==========================================================================
   2. HERO ANIMATED CAROUSEL WITH USER IMAGES
   ========================================================================== */
function initHeroCarousel() {
    const carouselContainer = document.getElementById('heroCarousel');
    const slides = document.querySelectorAll('.carousel-slide');
    const dots = document.querySelectorAll('.carousel-dot');
    const prevBtn = document.getElementById('carouselPrevBtn');
    const nextBtn = document.getElementById('carouselNextBtn');

    if (!slides || slides.length === 0) return;

    let currentIndex = 0;
    const totalSlides = slides.length;
    let autoPlayInterval = null;
    const slideDuration = 4500; // 4.5 seconds per slide

    function goToSlide(index) {
        // Normalize index
        if (index < 0) index = totalSlides - 1;
        if (index >= totalSlides) index = 0;

        slides.forEach((slide, i) => {
            if (i === index) {
                slide.classList.add('active');
            } else {
                slide.classList.remove('active');
            }
        });

        dots.forEach((dot, i) => {
            if (i === index) {
                dot.classList.add('active');
            } else {
                dot.classList.remove('active');
            }
        });

        currentIndex = index;
    }

    function startAutoPlay() {
        stopAutoPlay();
        autoPlayInterval = setInterval(() => {
            goToSlide(currentIndex + 1);
        }, slideDuration);
    }

    function stopAutoPlay() {
        if (autoPlayInterval) {
            clearInterval(autoPlayInterval);
            autoPlayInterval = null;
        }
    }

    if (prevBtn) {
        prevBtn.addEventListener('click', (e) => {
            e.preventDefault();
            goToSlide(currentIndex - 1);
            startAutoPlay();
        });
    }

    if (nextBtn) {
        nextBtn.addEventListener('click', (e) => {
            e.preventDefault();
            goToSlide(currentIndex + 1);
            startAutoPlay();
        });
    }

    dots.forEach((dot) => {
        dot.addEventListener('click', function () {
            const slideIndex = parseInt(this.getAttribute('data-slide') || '0', 10);
            goToSlide(slideIndex);
            startAutoPlay();
        });
    });

    if (carouselContainer) {
        carouselContainer.addEventListener('mouseenter', stopAutoPlay);
        carouselContainer.addEventListener('mouseleave', startAutoPlay);
    }

    // Initialize first slide and start autoplay
    goToSlide(0);
    startAutoPlay();
}

/* ==========================================================================
   3. SERVICE REQUESTS DONUT CHART (CHART.JS)
   Strict Palette:
   Completed:   #16A34A (Green)
   Pending:     #F59E0B (Amber/Yellow)
   Rejected:    #DC2626 (Red)
   In Progress: #F97316 (Primary Orange)
   NO BLUE!
   ========================================================================== */
let requestDonutChart = null;

function initServiceRequestsChart() {
    const canvas = document.getElementById('serviceRequestsChart');
    if (!canvas) return;

    const completed = parseInt(canvas.dataset.completed || '0', 10);
    const pending = parseInt(canvas.dataset.pending || '0', 10);
    const rejected = parseInt(canvas.dataset.rejected || '0', 10);
    const inProgress = parseInt(canvas.dataset.inProgress || '0', 10);
    const totalRequests = completed + pending + rejected + inProgress;

    const ctx = canvas.getContext('2d');

    // If no requests at all, display a subtle neutral empty ring
    const hasData = totalRequests > 0;
    const chartData = {
        labels: hasData ? ['Completed', 'Pending', 'Rejected', 'In Progress'] : ['No Data'],
        datasets: [{
            data: hasData ? [completed, pending, rejected, inProgress] : [1],
            backgroundColor: hasData ? [
                '#16A34A', // Completed (Green)
                '#F59E0B', // Pending (Yellow/Amber)
                '#DC2626', // Rejected (Red)
                '#F97316'  // In Progress (Orange)
            ] : ['#E2E8F0'],
            hoverBackgroundColor: hasData ? [
                '#15803D',
                '#D97706',
                '#B91C1C',
                '#EA580C'
            ] : ['#CBD5E1'],
            borderWidth: 3,
            borderColor: '#FFFFFF',
            hoverOffset: hasData ? 4 : 0
        }]
    };

    const config = {
        type: 'doughnut',
        data: chartData,
        options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '72%',
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    enabled: hasData,
                    backgroundColor: '#1F2937',
                    titleColor: '#FFFFFF',
                    bodyColor: '#F3F4F6',
                    borderColor: '#374151',
                    borderWidth: 1,
                    padding: 10,
                    displayColors: true,
                    callbacks: {
                        label: function (context) {
                            if (!hasData) return ' No Requests recorded';
                            const total = context.dataset.data.reduce((a, b) => a + b, 0);
                            const val = context.raw || 0;
                            const pct = total > 0 ? ((val / total) * 100).toFixed(1) : '0.0';
                            return ` ${context.label}: ${val} (${pct}%)`;
                        }
                    }
                }
            },
            animation: {
                animateScale: true,
                animateRotate: true,
                duration: 900
            }
        }
    };

    if (typeof Chart !== 'undefined') {
        requestDonutChart = new Chart(ctx, config);
    }
}

/* ==========================================================================
   4. DYNAMIC TIME FILTER HANDLER
   ========================================================================== */
function initTimeFilter() {
    const filterSelect = document.getElementById('chartTimeFilter');
    if (!filterSelect || !requestDonutChart) return;

    let periodData = null;
    const statsScript = document.getElementById('adminPeriodStats');
    if (statsScript) {
        try {
            periodData = JSON.parse(statsScript.textContent.trim());
        } catch (e) {
            console.warn('Could not parse adminPeriodStats:', e);
        }
    }

    filterSelect.addEventListener('change', function () {
        const period = this.value;
        let c = 0, p = 0, r = 0, ip = 0, totalCount = 0;

        if (periodData && periodData[period]) {
            const d = periodData[period];
            c = parseInt(d.completed || 0, 10);
            p = parseInt(d.pending || 0, 10);
            r = parseInt(d.rejected || 0, 10);
            ip = parseInt(d.inProgress || 0, 10);
            totalCount = parseInt(d.total || (c + p + r + ip), 10);
        } else {
            const canvas = document.getElementById('serviceRequestsChart');
            c = parseInt(canvas.dataset.completed || '0', 10);
            p = parseInt(canvas.dataset.pending || '0', 10);
            r = parseInt(canvas.dataset.rejected || '0', 10);
            ip = parseInt(canvas.dataset.inProgress || '0', 10);
            totalCount = c + p + r + ip;
        }

        const hasRecords = totalCount > 0;
        if (hasRecords) {
            requestDonutChart.data.labels = ['Completed', 'Pending', 'Rejected', 'In Progress'];
            requestDonutChart.data.datasets[0].data = [c, p, r, ip];
            requestDonutChart.data.datasets[0].backgroundColor = ['#16A34A', '#F59E0B', '#DC2626', '#F97316'];
            requestDonutChart.data.datasets[0].hoverBackgroundColor = ['#15803D', '#D97706', '#B91C1C', '#EA580C'];
            requestDonutChart.options.plugins.tooltip.enabled = true;
        } else {
            requestDonutChart.data.labels = ['No Data'];
            requestDonutChart.data.datasets[0].data = [1];
            requestDonutChart.data.datasets[0].backgroundColor = ['#E2E8F0'];
            requestDonutChart.data.datasets[0].hoverBackgroundColor = ['#CBD5E1'];
            requestDonutChart.options.plugins.tooltip.enabled = false;
        }

        requestDonutChart.update();

        const centerCountEl = document.getElementById('centerTotalCount');
        if (centerCountEl) {
            centerCountEl.textContent = totalCount;
        }

        updateLegend(c, p, r, ip, totalCount);
    });
}

function updateLegend(c, p, r, ip, total) {
    setLegendItem('legendCompletedCount', 'legendCompletedPct', c, total);
    setLegendItem('legendPendingCount', 'legendPendingPct', p, total);
    setLegendItem('legendRejectedCount', 'legendRejectedPct', r, total);
    setLegendItem('legendInProgressCount', 'legendInProgressPct', ip, total);
}

function setLegendItem(countId, pctId, count, total) {
    const cEl = document.getElementById(countId);
    const pEl = document.getElementById(pctId);
    if (cEl) cEl.textContent = count;
    if (pEl) {
        const pct = total > 0 ? ((count / total) * 100).toFixed(1) : 0;
        pEl.textContent = `(${pct}%)`;
    }
}

/* ==========================================================================
   5. LIVE SEARCH FILTER (TABLE ROWS)
   ========================================================================== */
function initSearchFilter() {
    const searchInput = document.getElementById('globalSearchInput');
    const tableBody = document.getElementById('recentRequestsTableBody');
    if (!searchInput || !tableBody) return;

    searchInput.addEventListener('input', function () {
        const query = this.value.toLowerCase().trim();
        const rows = tableBody.querySelectorAll('tr');

        rows.forEach(row => {
            const text = row.textContent.toLowerCase();
            if (text.includes(query)) {
                row.style.display = '';
            } else {
                row.style.display = 'none';
            }
        });
    });
}
