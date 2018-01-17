$(document).ready(function() {
    var list = $('#uploads').data('listing-url');
    var messages = {};
    $.get("/api/lexicon.json", function(data) {
        messages = data;
    });

    function parse_uris_data (data) {
        console.log(data);
		if (data.uris) {
            for (var i = 0; i < data.uris.length; i++) {
                var uri = data.uris[i];
                var img;
                if (uri.match(/\.(png|jpe?g)$/)) {
                    img = $('<img/>', {
                        class: "img-responsive img-thumbnail",
                        src: uri,
                        alt: uri
                    });
                }
                else {
                    img = $('<span/>', { class: "fa fa-file-pdf-o fa-2x fa-border" });
                }
				$('#uploads').append(
                    $("<div/>", { 'class': 'upload-item  col-sm-6 col-md-4' }).append(
                        $('<div/>', { class: "thumbnail" }).append(
                            img,
                            $('<div/>', { class: "caption" }).append(
                                $('<code/>').text(uri)
                            )
                        )
                    )
                );
                if (data.insert) {
                    var body = $('#maintextarea').val();
                    if (uri.match(/\.pdf$/)) {
                        if (body.match(/^#ATTACH .*$/m)) {
                            body = body.replace(/^(#ATTACH .*)$/m, '$1 ' + uri);
                        }
                        else {
                            body = '#ATTACH ' + uri + "\n" + body;
                        }
                    }
                    else {
                        body = body + "\n\n[[" + uri + "]]\n\n";
                    }
                    $('#maintextarea').val(body)
                }
            }
		}
        else {
			//our application returned an error
            $('#uploads-errors').text(data.error.message).show();
		}
    }
    if (list) {
        $.get(list, function(data) {
            parse_uris_data(data, $('#uploads'));
        });
    }
    $('#attachment').change(function() {
        var target = $(this).data('upload-url');
        if (target) {
            $(this).simpleUpload(target, {
                start: function(file) {
				    //upload started
                    $('#uploads-errors').hide();
				    this.progressBar = $('<div/>', { class: "progress-bar",
                                                     role: "progressbar",
                                                     style: "width: 1%" });
                    this.progressBar.text('0%');
				    $('#upload-progress').append(this.progressBar);
			    },
			    progress: function(progress) {
				    //received progress
                    console.log("Progress: " + progress);
				    this.progressBar.css("width", progress + "%");
                    this.progressBar.text(progress + "%");
			    },
			    success: function(data) {
				    //upload successful
				    this.progressBar.remove();
                    parse_uris_data(data);
			    },
			    error: function(error) {
				    //upload failed
                    console.log(error);
				    this.progressBar.remove();
                    $('#uploads-errors').text(messages[error.name]).show();
			    },
                maxFileSize: 8 * 1028 * 1028,
                data: {
                    insert: $("#add-attachment-to-body").is(":checked") ? 1 : 0,
                    split_pdf: $("#split-pdf").is(":checked") ? 1 : 0,
                },
                expect: "json",
                allowedExts: ["pdf", "jpg", "jpeg", "png" ],
                allowedTypes: ["application/pdf", "image/png", "image/jpeg"]
		    });
        }
    });
});
