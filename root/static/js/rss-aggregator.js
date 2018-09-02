function rss_aggregate(element, feeds) {
    feeds.forEach(function(feed) {
        console.log(feed);
        $.ajax({
            url: feed,
            dataType: "xml",
        }).done(function(data) {
            var site_title = $(data).find("channel").children("title").first().text();
            var site_url = $(data).find("channel").children("link").first().text();
            var widget = $("<div/>", { 'class': "rss-aggregate-widget list-group" });
            widget.append($("<a/>", { class: "rss-aggregate-site-title list-group-item clearfix",
                                      href: site_url }).text(site_title));

            $(data).find("item").each(function() {
                var el = $(this);
                var item_el = $("<a/>", { 'class': "rss-aggregate-item list-group-item clearfix",
                                          'href': el.find("link").text()
                                        }).text(el.find("title").text());
                widget.append(item_el);
            });
            element.append(widget);
        });
    });
}
