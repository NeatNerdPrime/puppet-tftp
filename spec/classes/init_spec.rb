require 'spec_helper'

describe 'tftp' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:syslinux_package) do
        case facts[:os]['family']
        when 'Debian'
          %w[syslinux-common pxelinux]
        else
          %w[syslinux]
        end
      end

      it { should compile.with_all_deps }

      it 'should include classes' do
        should contain_class('tftp::install')
        should contain_class('tftp::config')
        should contain_class('tftp::service')
      end

      it 'should install default package' do
        tftp_package = case facts[:os]['family']
                       when 'RedHat'
                         'tftp-server'
                       when 'Debian'
                         'tftpd-hpa'
                       else
                         'tftp-hpa'
                       end

        should contain_package(tftp_package)
          .with_ensure('installed')
          .with_alias('tftp-server')

        syslinux_package.each do |p|
          should contain_package(p).with_ensure('installed')
        end
      end

      case facts[:os]['family']
      when 'RedHat'
        it 'should contain the service' do
          should contain_service('tftp.socket')
            .with_ensure('running')
            .with_enable('true')
            .with_alias('tftpd')
            .that_subscribes_to('Class[Tftp::Config]')
        end
      when 'FreeBSD'
        it 'should contain the service' do
          should contain_service('tftpd')
            .with_ensure('running')
            .with_enable('true')
            .with_alias('tftpd')
            .that_subscribes_to('Class[Tftp::Config]')
        end
      when 'Archlinux'
        it 'should contain the service' do
          should contain_service('tftpd.socket')
            .with_ensure('running')
            .with_enable('true')
            .with_alias('tftpd')
            .that_subscribes_to('Class[Tftp::Config]')
        end
      else
        it 'should contain the service' do
          should contain_service('tftpd-hpa')
            .with_ensure('running')
            .with_enable('true')
            .with_alias('tftpd')
            .that_subscribes_to('Class[Tftp::Config]')
        end
      end

      context 'with custom tftp package set to tftp-hpa-destruct' do
        let :params do
          {
            package: 'tftp-hpa-destruct'
          }
        end

        it 'should install custom tftp package' do
          should contain_package('tftp-hpa-destruct')
            .with_ensure('installed')
            .with_alias('tftp-server')
        end
      end

      context 'with custom syslinux package set to my-own-syslinux' do
        let :params do
          {
            syslinux_package: 'my-own-syslinux'
          }
        end
        it 'should install custom syslinux package' do
          should contain_package('my-own-syslinux').with_ensure('installed')
        end
      end

      context 'with syslinux package management set to false' do
        let :params do
          {
            manage_syslinux_package: false
          }
        end
        it 'should not install a syslinux package' do
          syslinux_package.each do |p|
            should_not contain_package(p)
          end
        end
      end
    end
  end
end
