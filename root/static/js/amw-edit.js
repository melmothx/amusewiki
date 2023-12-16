$(document).ready(function() {
    $('.bump-pubdate').on('click', function() {
        var maintextarea = $('#maintextarea');
        console.log("Bumping pubdate");
        maintextarea.attr('readonly', 'readonly');
        var body = maintextarea.val();
        var now = new Date();
        var formatted = now.toISOString()
        if (body.match(/^#pubdate .*$/m)) {
            body = body.replace(/^#pubdate .*$/m, '#pubdate ' + formatted);
        }
        else {
            body = '#pubdate ' + formatted + "\n" + body;
        }
        maintextarea.val(body);
        maintextarea.removeAttr('readonly');
        maintextarea.effect("highlight", {}, 1000);
    });
});
