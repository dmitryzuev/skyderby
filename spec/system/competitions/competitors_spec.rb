feature 'Event competitors', type: :system, js: true do
  scenario 'add competitor with existing profile' do
    event = create :event, responsible: user
    section = create :event_section, event: event

    suit = create :suit
    profile = create :profile, name: 'Ivan Petrov'

    sign_in user
    visit event_path(event)
    click_link I18n.t('activerecord.models.event/competitor')
    expect(page).to have_css('.modal-title', text: "#{I18n.t('activerecord.models.event/competitor')}: New")

    find('#select2-profile_id-container').click
    first('li.select2-results__option', text: profile.name).click

    find('#select2-suit_id-container').click
    first('li.select2-results__option', text: suit.name).click

    click_button I18n.t('general.save')
    sleep 0.5

    expect(page).to have_content(profile.name)
  end

  scenario 'add competitor with new profile' do
    event = create :event, responsible: user
    section = create :event_section, event: event

    suit = create :suit
    country = create :country
    profile_name = 'Ivan Petrov'

    sign_in user
    visit event_path(event)
    click_link I18n.t('activerecord.models.event/competitor')
    expect(page).to have_css('.modal-title', text: "#{I18n.t('activerecord.models.event/competitor')}: New")

    find('label', text: I18n.t('competitors.form.create_profile')).click

    fill_in 'competitor_name', with: profile_name
    find('#select2-country_id-container').click
    first('li.select2-results__option', text: country.name).click

    find('#select2-suit_id-container').click
    first('li.select2-results__option', text: suit.name).click

    click_button I18n.t('general.save')
    sleep 0.5

    expect(page).to have_content(profile_name)
  end

  def user
    @user ||= create :user
  end
end
