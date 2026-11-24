/**
 * On Road Vehicle Breakdown Assistance
 * Universal Master Responsive Engine
 * Zero-Blue Strict Palette (#F97316, #EA580C, #111827, #1F2937, #F8FAFC)
 * Supports all viewports: 320px up to 2560px
 */

(function () {
    'use strict';

    // Prevent duplicate initializations if script is loaded multiple times
    if (window.__appResponsiveEngineLoaded) return;
    window.__appResponsiveEngineLoaded = true;

    // Run when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initAllResponsiveFeatures);
    } else {
        initAllResponsiveFeatures();
    }

    function initAllResponsiveFeatures() {
        initSidebarsAndDrawers();
        initTableToCardTransformation();
        initResponsiveModals();
        initResponsiveDropdowns();
        initResponsiveForms();

        // Re-check tables when window resizes across breakpoint
        let resizeTimer;
        window.addEventListener('resize', function () {
            clearTimeout(resizeTimer);
            resizeTimer = setTimeout(function () {
                initTableToCardTransformation();
            }, 250);
        });
    }

    /* ==========================================================================
       1. SIDEBAR & OFF-CANVAS DRAWER SYSTEM
       Master Universal Delegated Engine - Strict Single Authority
       Supports Admin, Mechanic, and User modules seamlessly
       ========================================================================== */
    function getAllBackdrops() {
        let backdrops = Array.from(document.querySelectorAll('.sidebar-backdrop, .mech-sidebar-backdrop, .user-sidebar-backdrop'));
        if (backdrops.length === 0) {
            const newBd = document.createElement('div');
            newBd.className = 'sidebar-backdrop';
            document.body.appendChild(newBd);
            backdrops = [newBd];
        }
        return backdrops;
    }

    window.openAppSidebar = function (targetSidebar) {
        if (!targetSidebar) {
            targetSidebar = document.getElementById('adminSidebar') ||
                            document.getElementById('userSidebar') ||
                            document.getElementById('mechSidebar') ||
                            document.querySelector('.sidebar, .user-sidebar, .mech-sidebar');
        }
        if (!targetSidebar) return;

        targetSidebar.classList.add('open');
        targetSidebar.classList.add('show-sidebar');

        const backdrops = getAllBackdrops();
        backdrops.forEach(bd => {
            bd.classList.add('active');
            bd.classList.add('show');
        });

        document.body.classList.add('drawer-open');
        document.body.style.overflow = 'hidden';
    };

    window.closeAppSidebar = function () {
        const sidebars = document.querySelectorAll('#adminSidebar, #mechSidebar, #userSidebar, .sidebar, .mech-sidebar, .user-sidebar');
        sidebars.forEach(sb => {
            sb.classList.remove('open');
            sb.classList.remove('show-sidebar');
        });

        const backdrops = getAllBackdrops();
        backdrops.forEach(bd => {
            bd.classList.remove('active');
            bd.classList.remove('show');
        });

        document.body.classList.remove('drawer-open');
        document.body.style.overflow = '';
    };

    window.toggleAppSidebar = function (triggerBtn) {
        let targetSidebar = null;
        if (triggerBtn) {
            if (triggerBtn.id === 'menuToggleBtn' || triggerBtn.closest('.top-header') || triggerBtn.closest('.admin-topbar') || triggerBtn.closest('.header')) {
                targetSidebar = document.getElementById('adminSidebar') || document.querySelector('.sidebar');
            } else if (triggerBtn.id === 'mechSidebarToggle' || triggerBtn.closest('.mech-top-navbar') || triggerBtn.closest('.mech-topbar')) {
                targetSidebar = document.getElementById('mechSidebar') || document.querySelector('.mech-sidebar');
            } else if (triggerBtn.id === 'userSidebarToggle' || triggerBtn.closest('.user-top-navbar') || triggerBtn.closest('.user-topbar')) {
                targetSidebar = document.getElementById('userSidebar') || document.querySelector('.user-sidebar');
            }
        }

        if (!targetSidebar) {
            targetSidebar = document.getElementById('adminSidebar') ||
                            document.getElementById('userSidebar') ||
                            document.getElementById('mechSidebar') ||
                            document.querySelector('.sidebar, .user-sidebar, .mech-sidebar');
        }

        if (!targetSidebar) return;

        const isOpen = targetSidebar.classList.contains('open') || targetSidebar.classList.contains('show-sidebar');
        if (isOpen) {
            window.closeAppSidebar();
        } else {
            window.openAppSidebar(targetSidebar);
        }
    };

    function initSidebarsAndDrawers() {
        // Neutralize conflicting legacy inline onclick properties
        const toggles = document.querySelectorAll(
            '#menuToggleBtn, #mechSidebarToggle, #userSidebarToggle, .hamburger-btn, .btn-sidebar-toggle'
        );
        toggles.forEach(btn => {
            btn.onclick = null;
        });

        // Universal Click Delegation on document (Immune to DOM re-renders or multiple scripts)
        document.addEventListener('click', function (e) {
            // 1. Toggle Button Click
            const toggleBtn = e.target.closest('#menuToggleBtn, #mechSidebarToggle, #userSidebarToggle, .hamburger-btn, .btn-sidebar-toggle');
            if (toggleBtn) {
                e.stopPropagation();
                e.preventDefault();
                window.toggleAppSidebar(toggleBtn);
                return;
            }

            // 2. Explicit Close Button Click
            const closeBtn = e.target.closest('.sidebar-close-btn, #adminSidebarCloseBtn, #userSidebarCloseBtn, #mechSidebarCloseBtn');
            if (closeBtn) {
                e.stopPropagation();
                e.preventDefault();
                window.closeAppSidebar();
                return;
            }

            // 3. Backdrop Click
            const backdrop = e.target.closest('.sidebar-backdrop, .mech-sidebar-backdrop, .user-sidebar-backdrop');
            if (backdrop) {
                e.stopPropagation();
                e.preventDefault();
                window.closeAppSidebar();
                return;
            }

            // 4. Navigation Link Click inside open drawer on mobile (< 1024px)
            const navLink = e.target.closest('.sidebar-nav a, .user-sidebar-menu a, .mech-sidebar-menu a, .sidebar-link, .nav-link');
            if (navLink && window.innerWidth < 1024) {
                window.closeAppSidebar();
            }
        });

        // Close on Escape key
        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape') {
                window.closeAppSidebar();
            }
        });
    }

    /* ==========================================================================
       2. TABLE TO VERTICAL CARD LIST TRANSFORMATION (< 768px)
       Strict Requirement 3 Compliance:
       - Header: Avatar/Icon + Title on left with ID above it, Status badge on right
       - Thin divider lines
       - Body: [Icon + Label] left-aligned, [Value] right-aligned, multiple lines wrap cleanly
       - Footer: Full width action buttons with eye/check icons
       - One data source (the existing HTML table), zero duplicated queries
       ========================================================================== */
    function initTableToCardTransformation() {
        const tables = document.querySelectorAll(
            'table.sr-custom-table, table.sr-data-table, table.mech-data-table, ' +
            'table.pr-data-table, table.ar-data-table, table.sh-data-table, ' +
            'table.sh-table, table.user-table, table.blocked-table, ' +
            'table.approval-table, table.recent-requests-table, .responsive-table table, ' +
            '.sr-table-responsive table, .sr-table-container table, .pr-table-container table, ' +
            '.ar-table-container table, .sh-table-container table'
        );

        tables.forEach(table => {
            // Find or create card container
            let parentWrapper = table.closest('.sr-table-responsive, .sr-table-container, .pr-table-container, .ar-table-container, .sh-table-container, .table-container') || table.parentElement;
            let cardContainer = parentWrapper.querySelector('.responsive-mobile-cards-container');

            if (!cardContainer) {
                cardContainer = document.createElement('div');
                cardContainer.className = 'responsive-mobile-cards-container';
                parentWrapper.appendChild(cardContainer);
            }

            // Extract headers
            const thElements = Array.from(table.querySelectorAll('thead th'));
            if (thElements.length === 0) return;

            const headers = thElements.map(th => th.innerText.replace(/\n/g, ' ').trim());

            // Process rows
            const rows = Array.from(table.querySelectorAll('tbody tr'));
            if (rows.length === 0) {
                cardContainer.innerHTML = '<div class="mobile-no-records">No records available.</div>';
                return;
            }

            // Check if single empty-message row
            if (rows.length === 1 && rows[0].querySelector('td[colspan]')) {
                cardContainer.innerHTML = '<div class="mobile-no-records">' + rows[0].querySelector('td').innerHTML + '</div>';
                return;
            }

            // Clear previous cards
            cardContainer.innerHTML = '';

            rows.forEach((tr, rowIndex) => {
                const cells = Array.from(tr.querySelectorAll('td'));
                if (cells.length === 0 || cells[0].hasAttribute('colspan')) return;

                let idText = '';
                let titleHtml = '';
                let avatarIconHtml = '';
                let statusBadgeHtml = '';
                let actionButtons = [];
                const detailRows = [];

                cells.forEach((td, colIdx) => {
                    const headerText = (headers[colIdx] || '').toLowerCase();
                    const cellHtml = td.innerHTML.trim();
                    const cellText = td.innerText.trim();

                    // 1. Identify Status Badge
                    if (headerText.includes('status') || td.querySelector('.badge, .badge-status, .sr-status-pill-table, [class*="status-"]')) {
                        statusBadgeHtml = cellHtml;
                        return;
                    }

                    // 2. Identify Actions Cell
                    if (headerText.includes('action') || colIdx === cells.length - 1 && td.querySelector('button, a.btn, a.btn-table-action, .sr-btn-eye')) {
                        const btns = td.querySelectorAll('button, a');
                        btns.forEach(b => actionButtons.push(b));
                        return;
                    }

                    // 3. Identify ID / Code
                    if ((headerText.includes('request id') || headerText.includes('ticket') || headerText.includes('id') || headerText.includes('#') || headerText === 's.no') && !idText) {
                        const pill = td.querySelector('.sr-ticket-badge, .sr-req-code-pill, .badge');
                        idText = pill ? pill.innerText.trim() : cellText;
                        if (headerText === 's.no' && !idText.includes('#')) {
                            idText = '#' + idText;
                        }
                        return;
                    }

                    // 4. Identify Primary Title / User / Customer Name
                    if ((headerText.includes('user') || headerText.includes('motorist') || headerText.includes('mechanic') || headerText.includes('name') || headerText.includes('customer')) && !titleHtml) {
                        // Check if cell has avatar/icon
                        const iconEl = td.querySelector('i, img, .user-avatar, .sr-user-avatar');
                        if (iconEl) {
                            avatarIconHtml = iconEl.outerHTML;
                        }
                        // Check if sub-code exists (like USR012)
                        const subCodeEl = td.querySelector('span:last-child, .user-code');
                        if (subCodeEl && subCodeEl.innerText.trim().startsWith('USR') || (subCodeEl && subCodeEl.innerText.trim().startsWith('MEC'))) {
                            if (idText) {
                                idText += ' • ' + subCodeEl.innerText.trim();
                            } else {
                                idText = subCodeEl.innerText.trim();
                            }
                        }
                        titleHtml = td.querySelector('.sr-user-name, strong, h4, span') ? td.querySelector('.sr-user-name, strong, h4, span').innerText.trim() : cellText;
                        return;
                    }

                    // 5. Secondary Detail Rows
                    let rowIcon = 'fa-circle-info';
                    if (headerText.includes('vehicle')) rowIcon = 'fa-car-side';
                    else if (headerText.includes('issue') || headerText.includes('problem')) rowIcon = 'fa-triangle-exclamation';
                    else if (headerText.includes('date') || headerText.includes('time')) rowIcon = 'fa-calendar-days';
                    else if (headerText.includes('location') || headerText.includes('address')) rowIcon = 'fa-location-dot';
                    else if (headerText.includes('mechanic') || headerText.includes('workshop')) rowIcon = 'fa-wrench';
                    else if (headerText.includes('phone') || headerText.includes('contact')) rowIcon = 'fa-phone';
                    else if (headerText.includes('email')) rowIcon = 'fa-envelope';
                    else if (headerText.includes('exp') || headerText.includes('experience')) rowIcon = 'fa-briefcase';

                    detailRows.push({
                        label: headers[colIdx] || 'Detail',
                        icon: rowIcon,
                        content: cellHtml
                    });
                });

                // Default Fallbacks
                if (!titleHtml) {
                    titleHtml = idText || ('Record #' + (rowIndex + 1));
                }
                if (!avatarIconHtml) {
                    avatarIconHtml = '<i class="fa-solid fa-file-lines" style="color:#F97316;"></i>';
                }

                // Construct Card DOM
                const card = document.createElement('div');
                card.className = 'mobile-table-card';

                // 1. Header
                const cardHeader = document.createElement('div');
                cardHeader.className = 'mobile-card-header';
                cardHeader.innerHTML = `
                    <div class="mobile-card-header-left">
                        ${idText ? `<span class="mobile-card-id">${idText}</span>` : ''}
                        <div class="mobile-card-title-row">
                            <div class="mobile-card-icon">${avatarIconHtml}</div>
                            <h4 class="mobile-card-title">${titleHtml}</h4>
                        </div>
                    </div>
                    <div class="mobile-card-status">${statusBadgeHtml}</div>
                `;
                card.appendChild(cardHeader);

                // Divider 1
                const div1 = document.createElement('div');
                div1.className = 'mobile-card-divider';
                card.appendChild(div1);

                // 2. Body Details
                const cardBody = document.createElement('div');
                cardBody.className = 'mobile-card-body';

                detailRows.forEach(item => {
                    const rowEl = document.createElement('div');
                    rowEl.className = 'mobile-card-row';
                    rowEl.innerHTML = `
                        <span class="mobile-card-label"><i class="fa-solid ${item.icon}"></i> ${item.label}</span>
                        <div class="mobile-card-value">${item.content}</div>
                    `;
                    cardBody.appendChild(rowEl);
                });
                card.appendChild(cardBody);

                // 3. Footer Actions (if buttons exist)
                if (actionButtons.length > 0) {
                    const div2 = document.createElement('div');
                    div2.className = 'mobile-card-divider';
                    card.appendChild(div2);

                    const cardFooter = document.createElement('div');
                    cardFooter.className = 'mobile-card-footer';

                    actionButtons.forEach(originalBtn => {
                        const btnClone = originalBtn.cloneNode(true);
                        btnClone.classList.add('mobile-action-btn');
                        
                        // Proxy click directly to original button so all listeners/handlers fire
                        btnClone.addEventListener('click', function (e) {
                            if (originalBtn.tagName.toLowerCase() === 'a' && originalBtn.href && !originalBtn.getAttribute('onclick')) {
                                window.location.href = originalBtn.href;
                            } else {
                                originalBtn.click();
                            }
                        });

                        cardFooter.appendChild(btnClone);
                    });

                    card.appendChild(cardFooter);
                }

                cardContainer.appendChild(card);
            });
        });
    }

    /* ==========================================================================
       3. RESPONSIVE MODAL DIALOGS
       Ensures max-width: 95vw, max-height: 90vh, internal scroll, no clip
       ========================================================================== */
    function initResponsiveModals() {
        const modals = document.querySelectorAll('.modal, .modal-overlay, .modal-backdrop, .sr-modal-overlay');

        modals.forEach(modal => {
            // Close on backdrop click outside dialog content
            modal.addEventListener('click', function (e) {
                if (e.target === this) {
                    this.style.display = 'none';
                    this.classList.remove('active');
                    this.classList.remove('show');
                    document.body.style.overflow = '';
                }
            });
        });

        // Close triggers
        document.querySelectorAll('[data-modal-close], .close-modal, .btn-modal-close, .modal-close-btn').forEach(btn => {
            btn.addEventListener('click', function () {
                const modal = this.closest('.modal, .modal-overlay, .modal-backdrop, .sr-modal-overlay') || 
                              document.querySelector('.modal.active, .modal-overlay.active, .modal-backdrop.active, .modal.show');
                if (modal) {
                    modal.style.display = 'none';
                    modal.classList.remove('active');
                    modal.classList.remove('show');
                    document.body.style.overflow = '';
                }
            });
        });
    }

    /* ==========================================================================
       4. RESPONSIVE DROPDOWNS & TOOLTIPS
       Keeps all dropdowns inside the viewport bounds
       ========================================================================== */
    function initResponsiveDropdowns() {
        document.querySelectorAll('.dropdown-toggle, [data-toggle="dropdown"]').forEach(btn => {
            btn.addEventListener('click', function () {
                const menu = this.nextElementSibling || this.parentElement.querySelector('.dropdown-menu, .profile-dropdown');
                if (!menu) return;

                // Check right boundary overflow
                const rect = menu.getBoundingClientRect();
                if (rect.right > window.innerWidth) {
                    menu.style.left = 'auto';
                    menu.style.right = '0';
                }
            });
        });
    }

    /* ==========================================================================
       5. RESPONSIVE FORMS & TOUCH TARGETS
       ========================================================================== */
    function initResponsiveForms() {
        // Ensure inputs are full-width on mobile
        const inputs = document.querySelectorAll('input, select, textarea');
        inputs.forEach(input => {
            input.addEventListener('focus', function () {
                // Prevent iOS zoom if font size is >= 16px
                if (window.innerWidth < 768 && window.getComputedStyle(this).fontSize < '16px') {
                    this.style.fontSize = '16px';
                }
            });
        });
    }

})();
