$(document).ready(function () {
    $.getJSON('test.json', function (json) {
        var tr;
        for (var i = 0; i < json.length; i++) {
            tr = $('<tr/>');
            tr.append("<td>" + json[i].software + "</td>");
            tr.append("<td>" + json[i].fullName + "</td>");
            tr.append("<td>" + json[i].softwareAbbrev + "</td>");
            tr.append("<td>" + json[i].releaseName + "</td>");
            tr.append("<td>" + json[i].sqlServerVersion + "</td>");
            tr.append("<td>" + json[i].buildDate + "</td>");
            tr.append("<td>" + json[i].releaseDate + "</td>");
            tr.append("<td>" + json[i].type + "</td>");
            tr.append("<td>" + json[i].releaseNote + "</td>");
            tr.append("<td>" + json[i].productsAffected + "</td>");
            tr.append("<td>" +
                "<a href=\"https://healthcatalyst.visualstudio.com/CAP/_workitems/edit/" +
                json[i].id + "\" target=\"_blank\">" + json[i].id + "</a>" + "</td>");
            $('table').append(tr);
        }
        var groupColumn = 1;
        var table = $('#notes').DataTable({
            //orderFixed: [2, 'asc'],
            keys: true,
            //stateSave: true,
            //responsive: true,
            colReorder: true,
            select: true,
            fixedHeader: true,
            "columnDefs": [{
                "visible": false,
                "targets": groupColumn
            }],
            buttons: [
                'copy', 'excel', 'csv'
            ],
            //Change order of elements on page
            dom: 'frBti',
            "displayLength": 5000,
            "order": [
                [groupColumn, 'desc']
            ],
            select: {
                style: 'os',
                //Deselect when you click outside the table
                blurable: true
            },

            "drawCallback": function (settings) {
                var api = this.api();
                var rows = api.rows({
                    page: 'current'
                }).nodes();
                var last = null;

                api.column(groupColumn, {
                    page: 'current'
                }).data().each(function (group, i) {
                    if (last !== group) {
                        $(rows).eq(i).before(
                            '<tr class="group"><td colspan="10">' +
                            group + '</td></tr>'
                        );

                        last = group;
                    }
                });
            }
        });

        // Order by the grouping
        $('#notes tbody').on('click', 'tr.group', function () {
            var currentOrder = table.order()[0];
            if (currentOrder[0] === groupColumn && currentOrder[1] === 'asc') {
                table.order([groupColumn, 'desc']).draw();
            } else {
                table.order([groupColumn, 'asc']).draw();
            }
        });

        //yadcf instructions
        'use strict';
        var oTable = $('#notes').DataTable();
        yadcf.init(oTable, [{
                    // Software
                    column_number: 0,
                    filter_type: 'multi_select',
                    select_type: 'chosen',
                    sort_as: 'alphaNum',
                    sort_order: "asc",
                    filter_match_mode: 'exact'
                },
                {
                    // Full name (not shown by default because table display is grouped on these rows)
                    column_number: 1,
                    filter_type: 'multi_select',
                    select_type: 'chosen',
                    filter_match_mode: 'exact'
                },
                {
                    // Version (aka root version number, e.g., DOS 18.1)
                    column_number: 2,
                    filter_type: 'multi_select',
                    select_type: 'chosen',
                    filter_match_mode: 'exact',
                    sort_as: 'alphaNum',
                    sort_order: "asc"
                },
                {
                    // Release (aka version number)
                    column_number: 3,
                    filter_type: 'multi_select',
                    select_type: 'chosen',
                    sort_order: 'asc',
                    sort_as: 'alphaNum',
                    filter_match_mode: 'exact'
                },
                {
                    // SQL Server version
                    column_number: 4,
                    filter_type: 'multi_select',
                    select_type: 'chosen',
                    filter_match_mode: 'exact',
                    sort_order: 'asc',
                    dropdownAutoWidth: true
                },
                {
                    // Build date
                    column_number: 5,
                    filter_type: 'multi_select',
                    sort_order: 'desc',
                    filter_match_mode: 'exact',
                    select_type: 'chosen',
                    date_format: "mm.dd.yyyy"
                },
                {
                    // Release date
                    column_number: 6,
                    filter_type: 'multi_select',
                    sort_order: 'desc',
                    filter_match_mode: 'exact',
                    select_type: 'chosen',
                    date_format: "mm.dd.yyyy"
                },
                {
                    // Type
                    column_number: 7,
                    filter_type: 'multi_select',
                    filter_match_mode: 'exact',
                    select_type: 'chosen'
                },
                //{
                //    Release note
                //    column_number: 8,
                //},            
                {
                    // Products affected
                    column_number: 9,
                    column_data_type: "html",
                    html_data_type: "selector",
                    filter_default_label: "Select product",
                    data: ['Atlas', 'CAP SQL 2016', 'DMCM', 'EDW Console', 'Fabric', 'IDEA',
                        'Install', 'Loader Engine', 'Platform General', 'SAMD',
                        'Services', 'SMD'
                    ]
                }
                //,{
                //    ID
                //    column_number: 10,
                //},
            ]
            // Cumulative not recommended because user can't select multiple releases
            //{
            //    cumulative_filtering: true
            //}
        );
    });
});