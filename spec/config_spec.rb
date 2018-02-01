require 'spec_helper'

describe Config do

  it "should get setting files" do
    config = Config.setting_files("root/config", "test")
    expect(config).to eq([
      'root/config/settings.yml',
      'root/config/settings/test.yml',
      'root/config/environments/test.yml',
      'root/config/settings.local.yml',
      'root/config/settings/test.local.yml',
      'root/config/environments/test.local.yml'
    ])
  end

  xit "should allow full reload of the settings files" do
    files = ["#{fixture_path}/settings.yml"]
    Config.load_and_set_settings(files)
    expect(Settings.server).to eq("google.com")
    expect(Settings.size).to eq(1)

    files = ["#{fixture_path}/settings.yml", "#{fixture_path}/development.yml"]
    Settings.reload_from_files(files)
    expect(Settings.server).to eq("google.com")
    expect(Settings.size).to eq(2)
  end

end
