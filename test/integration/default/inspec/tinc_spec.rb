control 'tinc-1' do
  title 'Tinc Setup'
  desc 'Check that tinc is installed'

  describe package('tinc') do
    it { should be_installed }
  end

end
