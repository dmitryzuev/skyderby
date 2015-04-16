var Event = Event || {};

Event.EventTrack = function(params) {
    this.id = '';
    this.round_id = '';
    this.competitor_id = '';
    this.track_id = '';
    this.result = '';
    this.url = '';
    this.track_presentation = '';

    this.$modal_form = $('#result-form-modal');
    this.$form = $('#result-form');
    this.$form_title = $('#result-form-modal-title');
    this.$form_competitor = $('#rm-competitor-name');
    this.$form_round = $('#rm-round-name');
    this.$form_track_label = $('#rm-track-label');
    this.$form_track_link = $('#rm-track-link');
    this.$form_new_track_wrap = $('#rm-new-track');

    this.$form_toggle_track = $('.toggle-track');
    this.$form_toggle_track_caption = $('.toggle-track-caption');

    this.$form_track_file_group = $('.track-file-group');
    this.$form_track_file_input = $('.track-file-input');
    this.$form_track_file_name = $('.track-file-name');

    this.$form_result_track = $('#result-track');

    this.$form_save = $('#rm-save');
    this.$form_delete_result = $('#rm-delete');

    $.extend(this, params);    

    this.is_new = !this.id;
}

Event.EventTrack.prototype = {
    open_form: function() {
        if (this.is_new) {
            modal_title = 'Добавление';
            this.$form_track_label.hide();
            this.$form_track_link.hide();
            this.$form_delete_result.hide();
            this.$form_new_track_wrap.show();
            this.$form_save.show();
        } else {
            modal_title = 'Редактирование';
            this.$form_save.hide();
            this.$form_new_track_wrap.hide();
            this.$form_track_label.show();
            this.$form_track_link.show();
            this.$form_delete_result.show();

            this.$form_track_link
                .text('#' + this.track_id)
                .attr('href', this.url);
        }

        var competitor = window.Competition.competitor_by_id(this.competitor_id);
        var round = window.Competition.round_by_id(this.round_id);

        this.$form_title.text('Результат: ' + modal_title);
        this.$form_competitor.text(competitor.profile.name);
        this.$form_round.text(capitaliseFirstLetter(round.discipline) + ' - ' + round.name);

        this.$form_result_track.find('option').remove();
        if (!this.is_new) {
            $('<option />', {value: this.track_id, text: this.track_presentation})
                .appendTo(this.$form_result_track);
        }       
 
        this.$form_result_track.select2({
            width: '100%',
            placeholder: "Choose track from list",
            dropdownParent: this.$modal_form,
            ajax: {
                url: '/api/tracks?filter[profile_id]=' + competitor.profile.id,
                dataType: 'json',
                type: "GET",
                quietMillis: 50,
                data: function (term) {
                    return {
                        query: term
                    };
                },
                processResults: function (data) {
                    return {
                        results: $.map(data, function (item) {
                            return {
                                text: item.presentation,
                                id: item.id
                            }
                        })
                    };
                },
                cache: true
            }
        });

        this.$form_toggle_track
            .off('click')
            .on('click', this.on_toggle_track.bind(this));

        this.$form_toggle_track.data('state', 'list');
        this.on_toggle_track();


        this.$form_save
            .off('click')
            .on('click', this.form_save.bind(this));

        this.$form_delete_result
            .off('click')
            .on('click', this.delete_result.bind(this));

        this.$modal_form.modal('show');
    },

    on_toggle_track: function(e) {
        if (e) {
            e.preventDefault();
        }
        // Если состояние = выбор из списка
        if (this.$form_toggle_track.data('state') == 'file') {
            // Переключаем в режим загрузки из файла
            // Скрываем группу выбора файла и меняем надпись
            this.$form_toggle_track.data('state', 'list').text('upload new one');
            this.$form_toggle_track_caption.text("Or");
            this.$form_track_file_group.hide();
            this.$form_track_file_input.val('');
            this.$form_track_file_name.val('');
            $('.result-track + span').show();
        } else {
            this.$form_toggle_track.data('state', 'file').text('select existed track');
            this.$form_toggle_track_caption.text("Or");
            this.$form_track_file_group.show();
            this.$form_result_track.select2('val', '');
            $('.result-track + span').hide()
        }
    },

    form_save: function(e) {
        e.preventDefault();

        this.track_id = this.$form_result_track.val();
        this.save();        

        this.$modal_form.modal('hide');
    },

    delete_result: function(e) {
        e.preventDefault();
        this.destroy();
        this.$modal_form.modal('hide');
    },

    save: function() {
        var url, method, data;

        if (this.is_new) {
            url = '/api/round_tracks/';
            method = 'POST';
        } else {
            url = '/api/round_tracks/' + this.id;
            method = 'PATCH';
        }

        data = {
            round_track: {
                round_id: this.round_id,
                competitor_id: this.competitor_id,
                track_id: this.track_id
            }
        };

        data = new FormData();
        data.append('round_track[round_id]', this.round_id);
        data.append('round_track[competitor_id]', this.competitor_id);
        if (this.track_id) {
            data.append('round_track[track_id]', this.track_id);
        } else {
            var cur_competitor = window.Competition.competitor_by_id(this.competitor_id);

            data.append('round_track[track_attributes[file]]', this.$form_track_file_input[0].files[0]);
            data.append('round_track[track_attributes[user_profile_id]]', cur_competitor.profile.id);
            data.append('round_track[track_attributes[wingsuit_id]]', cur_competitor.wingsuit.id);
        }

        $.ajax({
            url: url,
            method: method,
            dataType: 'json',
            data: data,
            cache: false,
            contentType: false,
            processData: false
        })
            .done(this.after_save.bind(this))
            .fail(fail_ajax_request);
 },

    destroy: function() {
        $.ajax({
            url: '/api/round_tracks/' + this.id,
            method: 'DELETE',
            dataType: 'json',
            context: {id: this.id}
        })
            .done(this.after_destroy.bind(this))
            .fail(fail_ajax_request);
    },

    after_save: function(data, status, jqXHR) {
        $.extend(this, data);
        this.is_new = !this.id;

        window.Competition.on_result_save(this);
},

    after_destroy: function() {
        window.Competition.on_result_delete(this);
    },
}
