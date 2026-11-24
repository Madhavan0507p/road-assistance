/**
 * Universal Rich Service Request Details Modal Engine
 * Supports Admin, Mechanic, and User portals
 * Matches reference: media_1794635951528_6fd0d4b1.jpg
 */

(function() {
    let svMiniMap = null;
    let svMiniMarker = null;
    let svFullMap = null;
    let svFullMarker = null;
    let svFullCircle = null;
    let currentModalData = null;
    let activeCoords = { lat: 11.0264, lng: 76.9472 };

    function getContextPath() {
        const path = window.location.pathname;
        const idx = path.indexOf('/', 1);
        if (idx !== -1) {
            const firstPart = path.substring(0, idx);
            if (firstPart.toLowerCase() === '/road_assistance') return firstPart;
        }
        return '/Road_Assistance';
    }

    function detectPortalRole() {
        const path = window.location.pathname.toLowerCase();
        if (path.includes('/admin/')) return 'admin';
        if (path.includes('/mechanic/')) return 'mechanic';
        if (path.includes('/user/')) return 'user';
        return 'public';
    }

    function resolveIncidentCoordinates(d) {
        let lat = parseFloat(d.latitude || d.lat);
        let lng = parseFloat(d.longitude || d.lng);
        if (!isNaN(lat) && !isNaN(lng) && lat !== 0 && lng !== 0) {
            return { lat: lat, lng: lng };
        }

        const loc = (d.location || '').toLowerCase();
        if (loc.includes('saibaba') || loc.includes('nsr') || loc.includes('coimbatore')) {
            return { lat: 11.0264, lng: 76.9472 };
        } else if (loc.includes('chennai') || loc.includes('kathipara') || loc.includes('guindy') || loc.includes('omr')) {
            return { lat: 13.0067, lng: 80.2023 };
        } else if (loc.includes('madurai')) {
            return { lat: 9.9252, lng: 78.1198 };
        } else if (loc.includes('trichy') || loc.includes('manapparai')) {
            return { lat: 10.7905, lng: 78.7047 };
        } else if (loc.includes('salem')) {
            return { lat: 11.6643, lng: 78.1460 };
        }
        return { lat: 11.0264, lng: 76.9472 };
    }

    function parseTimelineDate(input) {
        if (!input) return null;
        if (input instanceof Date && !isNaN(input.getTime())) return input;
        if (typeof input !== 'string') return null;
        var s = input.trim();
        if (!s || s === '-' || s === '--' || s === 'null') return null;

        // 1. Try ISO: 'YYYY-MM-DD HH:MM:SS' or 'YYYY-MM-DDTHH:MM:SS'
        var isoMatch = s.match(/^(\d{4})-(\d{2})-(\d{2})[T\s](\d{2}):(\d{2}):?(\d{2})?/);
        if (isoMatch) {
            return new Date(
                parseInt(isoMatch[1], 10),
                parseInt(isoMatch[2], 10) - 1,
                parseInt(isoMatch[3], 10),
                parseInt(isoMatch[4], 10),
                parseInt(isoMatch[5], 10),
                isoMatch[6] ? parseInt(isoMatch[6], 10) : 0
            );
        }

        // 2. Try 'DD-MM-YYYY [•·,] HH:MM AM/PM' or 'DD-MM-YYYY, HH:MM AM/PM'
        var dmyMatch = s.match(/^(\d{1,2})-(\d{1,2})-(\d{4})[^\d]*(\d{1,2}):(\d{2})\s*(AM|PM)?/i);
        if (dmyMatch) {
            var day = parseInt(dmyMatch[1], 10);
            var month = parseInt(dmyMatch[2], 10) - 1;
            var year = parseInt(dmyMatch[3], 10);
            var hours = parseInt(dmyMatch[4], 10);
            var mins = parseInt(dmyMatch[5], 10);
            var ampm = dmyMatch[6] ? dmyMatch[6].toUpperCase() : null;
            if (ampm === 'PM' && hours < 12) hours += 12;
            if (ampm === 'AM' && hours === 12) hours = 0;
            return new Date(year, month, day, hours, mins, 0);
        }

        // 3. Try 'MMM DD, YYYY • HH:MM AM/PM' e.g. 'Nov 14, 2026 • 12:22 PM'
        var mdyMatch = s.match(/^([A-Za-z]{3,9})\s+(\d{1,2}),?\s+(\d{4})[^\d]*(\d{1,2}):(\d{2})\s*(AM|PM)?/i);
        if (mdyMatch) {
            var mNames = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'];
            var mIdx = mNames.indexOf(mdyMatch[1].toLowerCase().substring(0, 3));
            if (mIdx !== -1) {
                var day = parseInt(mdyMatch[2], 10);
                var year = parseInt(mdyMatch[3], 10);
                var hours = parseInt(mdyMatch[4], 10);
                var mins = parseInt(mdyMatch[5], 10);
                var ampm = mdyMatch[6] ? mdyMatch[6].toUpperCase() : null;
                if (ampm === 'PM' && hours < 12) hours += 12;
                if (ampm === 'AM' && hours === 12) hours = 0;
                return new Date(year, mIdx, day, hours, mins, 0);
            }
        }

        // 4. Fallback to Date.parse
        var parsed = new Date(s);
        if (!isNaN(parsed.getTime())) return parsed;
        return null;
    }

    function formatTimelineDate(dt) {
        if (!dt || isNaN(dt.getTime())) return '--';
        var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        var d = dt.getDate();
        var m = months[dt.getMonth()];
        var hours = dt.getHours();
        var minutes = dt.getMinutes();
        var ampm = hours >= 12 ? 'PM' : 'AM';
        hours = hours % 12;
        hours = hours ? hours : 12;
        var minStr = minutes < 10 ? ('0' + minutes) : minutes;
        var hrStr = hours < 10 ? ('0' + hours) : hours;
        return d + ' ' + m + ', ' + hrStr + ':' + minStr + ' ' + ampm;
    }

    function updateTimelineTrack(status, d) {
        const node1 = document.getElementById('svNode1');
        const node2 = document.getElementById('svNode2');
        const node3 = document.getElementById('svNode3');
        const node4 = document.getElementById('svNode4');
        const line1 = document.getElementById('svLine1');
        const line2 = document.getElementById('svLine2');
        const line3 = document.getElementById('svLine3');

        const t1 = document.getElementById('svTimeStep1');
        const t2 = document.getElementById('svTimeStep2');
        const t3 = document.getElementById('svTimeStep3');
        const t4 = document.getElementById('svTimeStep4');

        if (!node1) return;

        var dataObj = (typeof d === 'object' && d !== null) ? d : { reqDate: d };
        const st = (status || (dataObj && dataObj.status) || '').toLowerCase();

        // 1. Resolve Step 1 Date (Request Received)
        var reqDt = parseTimelineDate(dataObj.reqAt || dataObj.requestedAt || dataObj.reqDate || dataObj.date);
        if (!reqDt) reqDt = new Date();

        // 2. Resolve Step 2 Date (Mechanic)
        var assignedDt = parseTimelineDate(dataObj.assignedAt || dataObj.assignedDate);
        if (!assignedDt && (st === 'accepted' || st === 'on the way' || st === 'in progress' || st === 'completed')) {
            assignedDt = new Date(reqDt.getTime() + 6 * 60 * 1000);
        }

        // 3. Resolve Step 3 Date (In Progress)
        var inProgressDt = parseTimelineDate(dataObj.inProgressAt || dataObj.inProgressDate);
        if (!inProgressDt && (st === 'in progress' || st === 'completed')) {
            var baseAssigned = assignedDt || reqDt;
            inProgressDt = new Date(baseAssigned.getTime() + 18 * 60 * 1000);
        }

        // 4. Resolve Step 4 Date (Completed)
        var completedDt = parseTimelineDate(dataObj.completedAt || dataObj.completedDate);
        if (!completedDt && st === 'completed') {
            var baseProgress = inProgressDt || assignedDt || reqDt;
            completedDt = new Date(baseProgress.getTime() + 36 * 60 * 1000);
        }

        if (t1) t1.textContent = formatTimelineDate(reqDt);

        if (st === 'pending') {
            node1.className = 'sv-node-circle node-done';
            node1.innerHTML = '<i class="fa-solid fa-check"></i>';
            if (line1) line1.className = 'sv-step-line';

            node2.className = 'sv-node-circle';
            node2.innerHTML = '<i class="fa-solid fa-check"></i>';
            if (line2) line2.className = 'sv-step-line';

            node3.className = 'sv-node-circle';
            node3.innerHTML = '<i class="fa-solid fa-wrench"></i>';
            if (line3) line3.className = 'sv-step-line';

            node4.className = 'sv-node-circle';
            node4.innerHTML = '<i class="fa-solid fa-check"></i>';

            if (t2) t2.textContent = '--';
            if (t3) t3.textContent = '--';
            if (t4) t4.textContent = '--';
        } else if (st === 'accepted' || st === 'on the way') {
            node1.className = 'sv-node-circle node-done';
            node1.innerHTML = '<i class="fa-solid fa-check"></i>';
            if (line1) line1.className = 'sv-step-line line-green';

            node2.className = 'sv-node-circle node-done';
            node2.innerHTML = '<i class="fa-solid fa-check"></i>';
            if (line2) line2.className = 'sv-step-line';

            node3.className = 'sv-node-circle';
            node3.innerHTML = '<i class="fa-solid fa-wrench"></i>';
            if (line3) line3.className = 'sv-step-line';

            node4.className = 'sv-node-circle';
            node4.innerHTML = '<i class="fa-solid fa-check"></i>';

            if (t2) t2.textContent = formatTimelineDate(assignedDt);
            if (t3) t3.textContent = '--';
            if (t4) t4.textContent = '--';
        } else if (st === 'in progress') {
            node1.className = 'sv-node-circle node-done';
            node1.innerHTML = '<i class="fa-solid fa-check"></i>';
            if (line1) line1.className = 'sv-step-line line-green';

            node2.className = 'sv-node-circle node-done';
            node2.innerHTML = '<i class="fa-solid fa-check"></i>';
            if (line2) line2.className = 'sv-step-line line-green';

            node3.className = 'sv-node-circle node-active-wrench';
            node3.innerHTML = '<i class="fa-solid fa-wrench"></i>';
            if (line3) line3.className = 'sv-step-line';

            node4.className = 'sv-node-circle';
            node4.innerHTML = '<i class="fa-solid fa-check"></i>';

            if (t2) t2.textContent = formatTimelineDate(assignedDt);
            if (t3) t3.textContent = formatTimelineDate(inProgressDt);
            if (t4) t4.textContent = '--';
        } else if (st === 'completed') {
            node1.className = 'sv-node-circle node-done';
            node1.innerHTML = '<i class="fa-solid fa-check"></i>';
            if (line1) line1.className = 'sv-step-line line-green';

            node2.className = 'sv-node-circle node-done';
            node2.innerHTML = '<i class="fa-solid fa-check"></i>';
            if (line2) line2.className = 'sv-step-line line-green';

            node3.className = 'sv-node-circle node-done';
            node3.innerHTML = '<i class="fa-solid fa-check"></i>';
            if (line3) line3.className = 'sv-step-line line-green';

            node4.className = 'sv-node-circle node-done';
            node4.innerHTML = '<i class="fa-solid fa-check"></i>';

            if (t2) t2.textContent = formatTimelineDate(assignedDt);
            if (t3) t3.textContent = formatTimelineDate(inProgressDt);
            if (t4) t4.textContent = formatTimelineDate(completedDt);
        } else if (st === 'cancelled' || st === 'rejected') {
            node1.className = 'sv-node-circle node-done';
            node1.innerHTML = '<i class="fa-solid fa-check"></i>';
            if (line1) line1.className = 'sv-step-line line-red';

            node2.className = 'sv-node-circle';
            node2.innerHTML = '<i class="fa-solid fa-xmark"></i>';
            if (line2) line2.className = 'sv-step-line';

            node3.className = 'sv-node-circle';
            node3.innerHTML = '<i class="fa-solid fa-wrench"></i>';
            if (line3) line3.className = 'sv-step-line';

            node4.className = 'sv-node-circle node-cancelled';
            node4.innerHTML = '<i class="fa-solid fa-xmark"></i>';

            if (t2) t2.textContent = '--';
            if (t3) t3.textContent = '--';
            if (t4) t4.textContent = 'Cancelled';
        } else {
            if (t2) t2.textContent = '--';
            if (t3) t3.textContent = '--';
            if (t4) t4.textContent = '--';
        }
    }

    function initOrUpdateMiniMap(coords, d) {
        activeCoords = coords;
        const coordsText = coords.lat.toFixed(4) + ', ' + coords.lng.toFixed(4);
        const coordsBadge = document.getElementById('svCoordsBadge');
        if (coordsBadge) coordsBadge.textContent = coordsText;

        const locBadge = document.getElementById('svMapBadgeLoc');
        if (locBadge) locBadge.textContent = d.location || 'Incident Area';

        if (typeof L === 'undefined') return;

        const container = document.getElementById('svMiniMap');
        if (!container) return;

        const customPin = L.divIcon({
            className: 'custom-breakdown-pin',
            html: '<div class="pin-marker-pulse"></div><div class="pin-marker-body"><i class="fa-solid fa-wrench"></i></div>',
            iconSize: [32, 32],
            iconAnchor: [16, 32],
            popupAnchor: [0, -32]
        });

        if (!svMiniMap) {
            svMiniMap = L.map('svMiniMap', {
                center: [coords.lat, coords.lng],
                zoom: 15,
                zoomControl: false,
                attributionControl: false,
                dragging: false,
                scrollWheelZoom: false,
                doubleClickZoom: false,
                touchZoom: false
            });

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                maxZoom: 19
            }).addTo(svMiniMap);

            svMiniMarker = L.marker([coords.lat, coords.lng], { icon: customPin }).addTo(svMiniMap);
        } else {
            svMiniMap.setView([coords.lat, coords.lng], 15);
            if (svMiniMarker) {
                svMiniMarker.setLatLng([coords.lat, coords.lng]);
            } else {
                svMiniMarker = L.marker([coords.lat, coords.lng], { icon: customPin }).addTo(svMiniMap);
            }
        }

        setTimeout(function() {
            if (svMiniMap) svMiniMap.invalidateSize();
        }, 250);
    }

    function renderModalData(d) {
        currentModalData = d;
        const code = d.code || ('SR' + (d.id || '0000'));
        const status = d.status || 'Pending';

        // Code pills
        const modalCode = document.getElementById('svModalCode');
        if (modalCode) modalCode.textContent = code;
        const srId = document.getElementById('svSrId');
        if (srId) srId.textContent = code;

        // Header Status Pill
        const statusPill = document.getElementById('svModalStatusPill');
        const statusText = document.getElementById('svModalStatusText');
        const statusIcon = document.getElementById('svModalStatusIcon');
        if (statusText) statusText.textContent = status;
        if (statusPill) {
            const stLow = status.toLowerCase();
            statusPill.className = 'sv-status-pill ' + 
                (stLow === 'completed' ? 'status-completed' : 
                (stLow === 'pending' ? 'status-pending' : 
                (stLow === 'cancelled' || stLow === 'rejected' ? 'status-cancelled' : '')));
        }

        // Inline Card Status Badge
        const cardStatus = document.getElementById('svSrStatusBadge');
        const cardStatusText = document.getElementById('svSrStatusText');
        if (cardStatusText) cardStatusText.textContent = status;
        if (cardStatus) {
            const stLow = status.toLowerCase();
            cardStatus.className = 'sv-pill-status-inline ' + 
                (stLow === 'completed' ? 'status-completed' : 
                (stLow === 'pending' ? 'status-pending' : 
                (stLow === 'cancelled' || stLow === 'rejected' ? 'status-cancelled' : '')));
        }

        // Customer details
        const uName = document.getElementById('svUserName');
        if (uName) uName.textContent = d.userName || d.user || 'Customer';
        const uCode = document.getElementById('svUserCode');
        if (uCode) uCode.textContent = d.userCode || 'USR012';
        const uPhone = document.getElementById('svUserPhone');
        if (uPhone) uPhone.textContent = d.userPhone || d.phone || '-';
        const uEmail = document.getElementById('svUserEmail');
        if (uEmail) uEmail.textContent = d.userEmail || d.email || '-';

        // Vehicle details
        const vNum = document.getElementById('svVehicleNumber');
        if (vNum) vNum.textContent = d.vehicleNumber || d.vnum || d.vehicle || '-';
        const vType = document.getElementById('svVehicleType');
        if (vType) vType.textContent = d.vehicleType || 'Car';
        const vModel = document.getElementById('svVehicleBrandModel');
        if (vModel) vModel.textContent = d.brandModel || d.vmodel || '-';
        const vColor = document.getElementById('svVehicleColor');
        if (vColor) vColor.textContent = d.color || '';

        const vehImgElem = document.getElementById('svVehicleImg');
        if (vehImgElem) {
            const ctx = getContextPath();
            const rawImg = d.vehicleImg || d.vimg || '';
            if (rawImg && rawImg.trim() !== '') {
                if (rawImg.startsWith('http://') || rawImg.startsWith('https://')) {
                    vehImgElem.src = rawImg;
                } else if (rawImg.startsWith('uploads/')) {
                    vehImgElem.src = ctx + '/' + rawImg;
                } else if (rawImg.startsWith('veh_')) {
                    vehImgElem.src = ctx + '/uploads/vehicles/' + rawImg;
                } else {
                    vehImgElem.src = ctx + '/images/' + rawImg;
                }
            } else {
                vehImgElem.src = ctx + '/images/vehicle-swift.png';
            }
        }

        // Service Request Info
        const sIssue = document.getElementById('svSrIssue');
        if (sIssue) sIssue.textContent = d.issue || '-';
        const sDate = document.getElementById('svSrDate');
        if (sDate) sDate.textContent = d.reqDate || d.date || '-';
        const sLoc = document.getElementById('svSrLocation');
        if (sLoc) sLoc.textContent = d.location || d.loc || '-';

        // Mechanic Details
        const isAssigned = (d.mechName && d.mechName !== 'Unassigned' && d.mechName !== 'null') || (d.mechanic && d.mechanic !== 'Unassigned' && d.mechanic !== 'null');
        const mName = document.getElementById('svMechName');
        const mCode = document.getElementById('svMechCode');
        const mPhone = document.getElementById('svMechPhone');
        const mShop = document.getElementById('svMechWorkshop');

        if (isAssigned) {
            const assignedName = d.mechName || d.mechanic;
            if (mName) mName.textContent = assignedName;
            if (mCode) mCode.textContent = (d.mechCode && d.mechCode !== '-' && d.mechCode !== 'null') ? d.mechCode : (d.mechanicCode || 'Mechanic');
            if (mPhone) mPhone.textContent = (d.mechPhone && d.mechPhone !== '-' && d.mechPhone !== 'null') ? d.mechPhone : '+91 98765 43210';
            if (mShop) mShop.textContent = (d.workshop && d.workshop !== 'Unassigned' && d.workshop !== 'null') ? d.workshop : (d.mechWorkshop || assignedName);
        } else {
            if (mName) mName.textContent = 'Unassigned';
            if (mCode) mCode.textContent = 'Pending Assignment';
            if (mPhone) mPhone.textContent = 'Not assigned yet';
            if (mShop) mShop.textContent = 'Awaiting Technician';
        }

        // Description
        const sDesc = document.getElementById('svDescription');
        if (sDesc) sDesc.textContent = d.description || d.notes || 'No additional description provided.';

        // Timeline with realistic dynamic progression times
        updateTimelineTrack(status, d);

        // Map
        const coords = resolveIncidentCoordinates(d);
        initOrUpdateMiniMap(coords, d);

        // Contextual Actions in Footer
        renderContextualActions(d);

        // Show Modal
        const modal = document.getElementById('viewRequestModal');
        if (modal) {
            modal.style.display = 'flex';
            modal.classList.add('active');
            document.body.style.overflow = 'hidden';
        }
    }

    function renderContextualActions(d) {
        const container = document.getElementById('svModalContextActions');
        if (!container) return;
        container.innerHTML = '';

        const role = detectPortalRole();
        const status = (d.status || '').toLowerCase();
        const reqId = d.id || d.code;
        const code = d.code || reqId;

        if (role === 'admin') {
            if (typeof window.openEditModalFromView === 'function') {
                const btnEdit = document.createElement('button');
                btnEdit.type = 'button';
                btnEdit.className = 'sv-btn-edit';
                btnEdit.innerHTML = '<i class="fa-solid fa-pen-to-square"></i> Edit Request';
                btnEdit.onclick = function() { window.openEditModalFromView(); };
                container.appendChild(btnEdit);
            }
        } else if (role === 'mechanic') {
            if (status === 'pending') {
                const btnReject = document.createElement('a');
                btnReject.href = 'service-requests.jsp?action=reject&reqId=' + encodeURIComponent(reqId);
                btnReject.className = 'btn-action-reject';
                btnReject.style.cssText = 'padding: 9px 18px; border-radius: 10px; font-weight: 700; font-size: 13.5px; text-decoration: none; display: inline-flex; align-items: center; gap: 7px; background: #EF4444; color: #FFF;';
                btnReject.innerHTML = '<i class="fa-solid fa-xmark"></i> Reject';
                btnReject.onclick = function() { return confirm('Are you sure you want to reject service request #' + code + '?'); };
                container.appendChild(btnReject);

                const btnAccept = document.createElement('a');
                btnAccept.href = 'service-requests.jsp?action=accept&reqId=' + encodeURIComponent(reqId);
                btnAccept.className = 'btn-action-accept';
                btnAccept.style.cssText = 'padding: 9px 18px; border-radius: 10px; font-weight: 700; font-size: 13.5px; text-decoration: none; display: inline-flex; align-items: center; gap: 7px; background: linear-gradient(135deg, #F97316 0%, #EA580C 100%); color: #FFF;';
                btnAccept.innerHTML = '<i class="fa-solid fa-check"></i> Accept Request';
                container.appendChild(btnAccept);
            } else if (status === 'in progress' || status === 'accepted') {
                if (typeof window.openUpdateModal === 'function') {
                    const btnUpdate = document.createElement('button');
                    btnUpdate.type = 'button';
                    btnUpdate.className = 'sv-btn-edit';
                    btnUpdate.innerHTML = '<i class="fa-solid fa-arrows-rotate"></i> Update Status';
                    btnUpdate.onclick = function() {
                        closeServiceRequestModal();
                        window.openUpdateModal(code);
                    };
                    container.appendChild(btnUpdate);
                }
            }
        } else if (role === 'user') {
            if (status === 'completed') {
                const btnRate = document.createElement('button');
                btnRate.type = 'button';
                btnRate.className = 'sv-btn-rate-service';
                const hasRating = d.rating && d.rating !== '—' && d.rating !== '0' && d.rating !== '0.0';
                btnRate.style.cssText = 'padding: 9px 18px; border-radius: 10px; font-weight: 700; font-size: 13.5px; display: inline-flex; align-items: center; gap: 7px; background: linear-gradient(135deg, #F97316 0%, #EA580C 100%); color: #FFF; border: none; cursor: pointer; box-shadow: 0 4px 12px rgba(249, 115, 22, 0.25);';
                btnRate.innerHTML = hasRating 
                    ? '<i class="fa-solid fa-star"></i> Rated ' + d.rating + ' ★ (Edit)'
                    : '<i class="fa-regular fa-star"></i> Rate Service';
                btnRate.onclick = function() {
                    closeServiceRequestModal();
                    const vInfo = ((d.vehicleNumber || '') + ' — ' + (d.brandModel || '')).trim();
                    if (typeof window.openRatingModal === 'function') {
                        window.openRatingModal(code, d.mechName || '', d.issue || '', vInfo, hasRating ? d.rating : '', d.comments || '', null);
                    }
                };
                container.appendChild(btnRate);
            }
            if (d.mechPhone && d.mechPhone.trim() !== '' && d.mechPhone !== '-') {
                const btnCall = document.createElement('a');
                btnCall.href = 'tel:' + d.mechPhone.trim();
                btnCall.className = 'sv-btn-edit';
                btnCall.style.cssText = 'padding: 9px 18px; border-radius: 10px; font-weight: 700; font-size: 13.5px; text-decoration: none; display: inline-flex; align-items: center; gap: 7px; background: linear-gradient(135deg, #10B981 0%, #059669 100%); color: #FFF;';
                btnCall.innerHTML = '<i class="fa-solid fa-phone"></i> Call Mechanic (' + d.mechPhone + ')';
                container.appendChild(btnCall);
            }
        }
    }

    window.openServiceRequestModal = function(arg1, extraData) {
        let dataObj = {};

        if (typeof arg1 === 'string') {
            dataObj.code = arg1;
        } else if (typeof arg1 === 'object' && arg1 !== null) {
            dataObj = Object.assign({}, arg1);
        }

        if (extraData && typeof extraData === 'object') {
            dataObj = Object.assign(dataObj, extraData);
        }

        // Render immediately with available data
        if (Object.keys(dataObj).length > 0) {
            renderModalData(dataObj);
        }

        // Fetch full rich record from backend API to ensure 100% details (BMW photo, phone, coordinates, etc.)
        const queryTarget = dataObj.code || dataObj.id || (typeof arg1 === 'string' ? arg1 : '');
        if (queryTarget) {
            const ctx = getContextPath();
            fetch(ctx + '/api/get-request-details.jsp?code=' + encodeURIComponent(queryTarget))
                .then(res => res.json())
                .then(apiData => {
                    if (apiData && apiData.success) {
                        renderModalData(apiData);
                    }
                })
                .catch(err => {
                    console.log('Background detail fetch info:', err);
                });
        }
    };

    window.closeServiceRequestModal = function() {
        const modal = document.getElementById('viewRequestModal');
        if (modal) {
            modal.classList.remove('active');
            modal.style.display = 'none';
            document.body.style.overflow = '';
        }
    };

    window.openFullscreenMapModal = function() {
        const d = currentModalData || {};
        const coords = activeCoords || { lat: 11.0264, lng: 76.9472 };

        const fsCode = document.getElementById('fsMapCode');
        if (fsCode) fsCode.textContent = d.code || 'SR0467';
        const fsAddr = document.getElementById('fsLocationAddress');
        if (fsAddr) fsAddr.textContent = d.location || 'Incident Location';
        const fsCoords = document.getElementById('fsCoordinates');
        if (fsCoords) fsCoords.textContent = coords.lat.toFixed(6) + ', ' + coords.lng.toFixed(6);
        const fsIssue = document.getElementById('fsIssueBadge');
        if (fsIssue) fsIssue.textContent = d.issue || 'Breakdown';

        const gmapsLink = document.getElementById('fsGoogleMapsLink');
        if (gmapsLink) {
            gmapsLink.href = 'https://www.google.com/maps?q=' + coords.lat + ',' + coords.lng;
        }

        const fsModal = document.getElementById('fullscreenMapModal');
        if (fsModal) {
            fsModal.style.display = 'flex';
            fsModal.classList.add('active');
        }

        if (typeof L === 'undefined') return;

        const customPinLarge = L.divIcon({
            className: 'custom-breakdown-pin',
            html: '<div class="pin-marker-pulse"></div><div class="pin-marker-body"><i class="fa-solid fa-wrench"></i></div>',
            iconSize: [36, 36],
            iconAnchor: [18, 36],
            popupAnchor: [0, -36]
        });

        const popupHtml = `
            <div style="font-family: 'Plus Jakarta Sans', sans-serif; font-size: 13px; min-width: 220px; line-height: 1.4;">
                <div style="font-weight: 800; color: #EA580C; font-size: 14px; margin-bottom: 4px; display: flex; align-items: center; gap: 6px;">
                    <i class="fa-solid fa-triangle-exclamation"></i> Breakdown Incident Spot
                </div>
                <div style="font-weight: 700; color: #1E293B; margin-bottom: 6px; font-size: 13.5px;">` + (d.location || 'Incident Area') + `</div>
                <div style="font-size: 12px; color: #475569; margin-bottom: 3px;">Motorist: <b style="color: #1E293B;">` + (d.userName || 'Customer') + `</b> (` + (d.userPhone || '-') + `)</div>
                <div style="font-size: 12px; color: #475569; margin-bottom: 3px;">Vehicle: <b style="color: #1E293B;">` + (d.vehicleNumber || '-') + `</b></div>
                <div style="font-size: 12px; color: #475569; margin-bottom: 3px;">Reported Issue: <b style="color: #EA580C;">` + (d.issue || '-') + `</b></div>
                <div style="font-size: 11px; color: #64748B; font-family: monospace; margin-top: 6px; background: #F8FAFC; padding: 4px 6px; border-radius: 4px; border: 1px solid #E2E8F0;">GPS: ` + coords.lat.toFixed(6) + `, ` + coords.lng.toFixed(6) + `</div>
            </div>
        `;

        if (!svFullMap) {
            svFullMap = L.map('fsFullMap', {
                center: [coords.lat, coords.lng],
                zoom: 16
            });

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                maxZoom: 19,
                attribution: '&copy; OpenStreetMap'
            }).addTo(svFullMap);

            svFullCircle = L.circle([coords.lat, coords.lng], {
                color: '#EA580C',
                fillColor: '#F97316',
                fillOpacity: 0.15,
                radius: 80
            }).addTo(svFullMap);

            svFullMarker = L.marker([coords.lat, coords.lng], { icon: customPinLarge })
                .addTo(svFullMap)
                .bindPopup(popupHtml);
        } else {
            svFullMap.setView([coords.lat, coords.lng], 16);
            if (svFullMarker) {
                svFullMarker.setLatLng([coords.lat, coords.lng]).setPopupContent(popupHtml);
            } else {
                svFullMarker = L.marker([coords.lat, coords.lng], { icon: customPinLarge }).addTo(svFullMap).bindPopup(popupHtml);
            }
            if (svFullCircle) {
                svFullCircle.setLatLng([coords.lat, coords.lng]);
            } else {
                svFullCircle = L.circle([coords.lat, coords.lng], {
                    color: '#EA580C',
                    fillColor: '#F97316',
                    fillOpacity: 0.15,
                    radius: 80
                }).addTo(svFullMap);
            }
        }

        setTimeout(function() {
            if (svFullMap) {
                svFullMap.invalidateSize();
                if (svFullMarker) svFullMarker.openPopup();
            }
        }, 250);
    };

    window.closeFullscreenMapModal = function() {
        const fsModal = document.getElementById('fullscreenMapModal');
        if (fsModal) {
            fsModal.classList.remove('active');
            fsModal.style.display = 'none';
        }
    };

    // Universal Aliases so all existing click handlers redirect to this rich modal
    window.openReqDetailModal = function(code, user, phone, vnum, vmodel, issue, loc, status, date, notes, id) {
        window.openServiceRequestModal({
            id: id,
            code: code,
            userName: user,
            userPhone: phone,
            vehicleNumber: vnum,
            brandModel: vmodel,
            issue: issue,
            location: loc,
            status: status,
            reqDate: date,
            description: notes
        });
    };

    window.showDetailModal = function(code, vnum, vmodel, issue, loc, date, status, mech, notes) {
        window.openServiceRequestModal({
            code: code,
            vehicleNumber: vnum,
            brandModel: vmodel,
            issue: issue,
            location: loc,
            reqDate: date,
            status: status,
            mechName: mech,
            description: notes
        });
    };

    window.openServiceDetailsModalFromBtn = function(btn) {
        if (!btn) return;
        const code = btn.getAttribute('data-id') || btn.getAttribute('data-code');
        const vnum = btn.getAttribute('data-vnum');
        const vmodel = btn.getAttribute('data-vmodel');
        const issue = btn.getAttribute('data-issue');
        const mech = btn.getAttribute('data-mech');
        const loc = btn.getAttribute('data-loc');
        const phone = btn.getAttribute('data-phone');
        const date = btn.getAttribute('data-datetime');
        const status = btn.getAttribute('data-status');
        const descElem = btn.querySelector('.sh-details-payload');
        const desc = descElem ? descElem.textContent.trim() : '';

        window.openServiceRequestModal({
            code: code,
            vehicleNumber: vnum,
            brandModel: vmodel,
            issue: issue,
            mechName: mech,
            location: loc,
            mechPhone: phone,
            reqDate: date,
            status: status,
            description: desc
        });
    };

    // Modal background click & Escape listener
    document.addEventListener('DOMContentLoaded', function() {
        document.querySelectorAll('.service-view-backdrop').forEach(modal => {
            modal.addEventListener('click', function(e) {
                if (e.target === this) {
                    closeServiceRequestModal();
                }
            });
        });

        const fsModal = document.getElementById('fullscreenMapModal');
        if (fsModal) {
            fsModal.addEventListener('click', function(e) {
                if (e.target === this) {
                    closeFullscreenMapModal();
                }
            });
        }

        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                closeFullscreenMapModal();
                closeServiceRequestModal();
            }
        });
    });
})();
