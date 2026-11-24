/**
 * Universal Table Pagination for On Road Vehicle Breakdown Assistance
 * Default page size: 10 rows per page
 * Handles dynamic row-slicing, pagination controls, rows-per-page dropdown, and counter updates.
 */

(function () {
    'use strict';

    function initTablePagination(table, options) {
        if (!table || table.dataset.paginated === 'true') return;
        table.dataset.paginated = 'true';

        var tbody = table.querySelector('tbody');
        if (!tbody) return;

        var allRows = Array.from(tbody.querySelectorAll('tr'));
        // Exclude empty-state or banner rows if any
        var rows = allRows.filter(function(r) {
            return !r.classList.contains('no-paginate') && !r.querySelector('.table-empty-state');
        });

        var pageSize = (options && options.pageSize) ? options.pageSize : 10;
        var currentPage = 1;

        // Find associated footer container
        var parentContainer = table.closest('.dashboard-card, .table-responsive-box, .table-responsive-wrapper, .mech-table-wrapper, .blocked-table-wrapper, .table-scroll-container, .desktop-table-view, main') || table.parentElement;
        var footer = parentContainer ? parentContainer.querySelector('.user-table-footer, .mech-table-footer, .table-footer-row, .pagination-container, .ar-footer-row, .pr-footer-row, .sr-pagination-footer') : null;
        
        // Rows per page dropdown
        var rowsSelect = footer ? footer.querySelector('.rows-select, select') : null;
        if (rowsSelect) {
            rowsSelect.value = pageSize.toString();
            rowsSelect.addEventListener('change', function () {
                var newSize = parseInt(this.value, 10);
                if (!isNaN(newSize) && newSize > 0) {
                    pageSize = newSize;
                    currentPage = 1;
                    render();
                }
            });
        }

        function render() {
            var totalRows = rows.length;
            var totalPages = Math.ceil(totalRows / pageSize) || 1;
            if (currentPage > totalPages) currentPage = totalPages;
            if (currentPage < 1) currentPage = 1;

            var startIndex = (currentPage - 1) * pageSize;
            var endIndex = Math.min(startIndex + pageSize, totalRows);

            // Toggle row visibility
            rows.forEach(function (row, idx) {
                if (idx >= startIndex && idx < endIndex) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });

            // Update footer text
            if (footer) {
                var entriesText = footer.querySelector('.table-entries-text, .footer-showing-text, .pr-record-count-text, .ar-record-count-text, .sr-record-count-text');
                if (entriesText) {
                    var unit = (table.id && table.id.toLowerCase().includes('mech')) ? 'mechanics' : ((table.id && table.id.toLowerCase().includes('user')) ? 'entries' : 'requests');
                    entriesText.innerText = 'Showing ' + (totalRows > 0 ? (startIndex + 1) : 0) + ' to ' + endIndex + ' of ' + totalRows + ' ' + unit;
                }

                // Update pagination buttons
                var controls = footer.querySelector('.pagination-controls, .pagination-pills, .ar-pagination-controls, .pr-pagination-controls, .sr-pagination-controls');
                if (controls) {
                    // Rebuild controls dynamically if client-side pagination is active
                    buildControls(controls, totalPages);
                }
            }
        }

        function buildControls(container, totalPages) {
            container.innerHTML = '';
            if (totalPages <= 1) return;

            // Prev Button
            var prevBtn = document.createElement('a');
            prevBtn.href = 'javascript:void(0)';
            prevBtn.className = 'page-btn page-num-btn btn-pr-page ' + (currentPage <= 1 ? 'disabled' : '');
            prevBtn.innerHTML = '<i class="fa-solid fa-chevron-left"></i>';
            prevBtn.title = 'Previous page';
            if (currentPage > 1) {
                prevBtn.addEventListener('click', function(e) {
                    e.preventDefault();
                    currentPage--;
                    render();
                });
            }
            container.appendChild(prevBtn);

            // Page numbers
            for (var p = 1; p <= totalPages; p++) {
                (function(page) {
                    var pageBtn = document.createElement('a');
                    pageBtn.href = 'javascript:void(0)';
                    pageBtn.className = 'page-btn page-num-btn btn-pr-page ' + (page === currentPage ? 'active active-page' : '');
                    pageBtn.innerText = page;
                    if (page === currentPage) {
                        pageBtn.style.background = '#F97316';
                        pageBtn.style.color = '#FFFFFF';
                        pageBtn.style.fontWeight = '700';
                    }
                    pageBtn.addEventListener('click', function(e) {
                        e.preventDefault();
                        currentPage = page;
                        render();
                    });
                    container.appendChild(pageBtn);
                })(p);
            }

            // Next Button
            var nextBtn = document.createElement('a');
            nextBtn.href = 'javascript:void(0)';
            nextBtn.className = 'page-btn page-num-btn btn-pr-page ' + (currentPage >= totalPages ? 'disabled' : '');
            nextBtn.innerHTML = '<i class="fa-solid fa-chevron-right"></i>';
            nextBtn.title = 'Next page';
            if (currentPage < totalPages) {
                nextBtn.addEventListener('click', function(e) {
                    e.preventDefault();
                    currentPage++;
                    render();
                });
            }
            container.appendChild(nextBtn);
        }

        // Only activate client pagination if table has more rows than pageSize in DOM
        if (rows.length > pageSize) {
            render();
        }
    }

    document.addEventListener('DOMContentLoaded', function () {
        var tables = document.querySelectorAll('table.user-table, table.mech-data-table, table.approval-table, table.blocked-table, table.pr-data-table, table.custom-table, table.recent-requests-table');
        tables.forEach(function (t) {
            initTablePagination(t, { pageSize: 10 });
        });
    });

    window.initTablePagination = initTablePagination;
})();
