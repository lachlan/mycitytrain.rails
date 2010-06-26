namespace :mycitytrain do
  namespace :db do
    desc "Destroys all journeys and stops older than today"
    task :purge => :environment do
      puts "Purging all journeys/stops before #{Time.zone.now.midnight}"
      older_than_today = ["departing_at < ?", Time.zone.now.midnight]
      Stop.destroy_all older_than_today
      Journey.destroy_all older_than_today
      
      puts "Purging all historic journeys older than #{30.days.ago}"
      HistoricJourney.destroy_all(["created_at < ?", 30.days.ago])
    end
    
    desc "Loads stations, journeys from Citytrain API"
    task :populate => :environment do
      # Load stations
      #CitytrainAPI.stations
      
      journeys = []
      journeys << ['BDT1','BNC']
      journeys << ['BDT1','ROB']
      journeys << ['AIN','BHI']
      journeys << ['AIN','BNC']
      journeys << ['AIN','WPT']
      journeys << ['ADY','BNC']
      journeys << ['ADY','MHQ']
      journeys << ['ACO','EGJ']
      journeys << ['AHF','CAB']
      journeys << ['AHF','BNC']
      journeys << ['AHF','BRC']
      journeys << ['AHF','TWG']
      journeys << ['BQY','BNC']
      journeys << ['BQY','BRC']
      journeys << ['BQY','SBA']
      journeys << ['BNH','TWG']
      journeys << ['BOV','BNC']
      journeys << ['BHI','AIN']
      journeys << ['BHI','BRD']
      journeys << ['BHI','FYG']
      journeys << ['BHI','NRG']
      journeys << ['BPR','BNC']
      journeys << ['BQU','BNC']
      journeys << ['BRD','BHI']
      journeys << ['BRD','BNC']
      journeys << ['BRD','IDP']
      journeys << ['BPY','BNC']
      journeys << ['BPY','BRC']
      journeys << ['CAB','AHF']
      journeys << ['CAB','BNC']
      journeys << ['CAB','EGJ']
      journeys << ['CAB','BRC']
      journeys << ['CAB','LSH']
      journeys << ['CAB','RS0']
      journeys << ['CNQ','BNC']
      journeys << ['CNQ','NPR']
      journeys << ['CDE','BNC']
      journeys << ['BNC','BDT1']
      journeys << ['BNC','AIN']
      journeys << ['BNC','ADY']
      journeys << ['BNC','AHF']
      journeys << ['BNC','BQY']
      journeys << ['BNC','BOV']
      journeys << ['BNC','BPR']
      journeys << ['BNC','BQU']
      journeys << ['BNC','BRD']
      journeys << ['BNC','BPY']
      journeys << ['BNC','CAB']
      journeys << ['BNC','CNQ']
      journeys << ['BNC','CDE']
      journeys << ['BNC','CVN']
      journeys << ['BNC','CEP']
      journeys << ['BNC','CRO']
      journeys << ['BNC','DIR']
      journeys << ['BNC','DBN']
      journeys << ['BNC','EGJ']
      journeys << ['BNC','EDL']
      journeys << ['BNC','EGG']
      journeys << ['BNC','FFI']
      journeys << ['BNC','BRC']
      journeys << ['BNC','GAO']
      journeys << ['BNC','GDQ']
      journeys << ['BNC','GOQ']
      journeys << ['BNC','IDP']
      journeys << ['BNC','IPS']
      journeys << ['BNC','LWO']
      journeys << ['BNC','LDM']
      journeys << ['BNC','MTZ']
      journeys << ['BNC','MHQ']
      journeys << ['BNC','MYE']
      journeys << ['BNC','MGS']
      journeys << ['BNC','MJE']
      journeys << ['BNC','NRB']
      journeys << ['BNC','NWM']
      journeys << ['BNC','NPR']
      journeys << ['BNC','NTG']
      journeys << ['BNC','OXL']
      journeys << ['BNC','PET']
      journeys << ['BNC','RDK']
      journeys << ['BNC','ROB']
      journeys << ['BNC','RKE']
      journeys << ['BNC','RS0']
      journeys << ['BNC','SBE']
      journeys << ['BNC','SYK']
      journeys << ['BNC','SSN']
      journeys << ['BNC','TIQ']
      journeys << ['BNC','TWG']
      journeys << ['BNC','VGI']
      journeys << ['BNC','WAC']
      journeys << ['BNC','WPT']
      journeys << ['BNC','WID']
      journeys << ['BNC','ZLL']
      journeys << ['CEP','BNC']
      journeys << ['CRO','BNC']
      journeys << ['CRO','NPR']
      journeys << ['CRO','SBE']
      journeys << ['CRO','TWG']
      journeys << ['CQD','GAO']
      journeys << ['DIR','BNC']
      journeys << ['DIR','EBV']
      journeys << ['DIR','RDK']
      journeys << ['DBN','BNC']
      journeys << ['EGJ','ACO']
      journeys << ['EGJ','CAB']
      journeys << ['EGJ','BNC']
      journeys << ['EBV','DIR']
      journeys << ['EDL','BNC']
      journeys << ['EDL','FFI']
      journeys << ['EGG','BNC']
      journeys << ['FFI','BNC']
      journeys << ['FFI','EDL']
      journeys << ['FFI','BRC']
      journeys << ['FYG','BHI']
      journeys << ['FYG','SBE']
      journeys << ['BRC','BQY']
      journeys << ['BRC','BPY']
      journeys << ['BRC','CAB']
      journeys << ['BRC','FFI']
      journeys << ['BRC','LWO']
      journeys << ['GAI','TWG']
      journeys << ['GAO','BNC']
      journeys << ['GAO','CQD']
      journeys << ['GAO','SBE']
      journeys << ['GAO','WID']
      journeys << ['GDQ','BNC']
      journeys << ['GDQ','TWG']
      journeys << ['GOQ','BNC']
      journeys << ['GOQ','RS0']
      journeys << ['IDP','BRD']
      journeys << ['IDP','BNC']
      journeys << ['IPS','BNC']
      journeys << ['LSH','CAB']
      journeys << ['LWO','BNC']
      journeys << ['LWO','BRC']
      journeys << ['LDM','BNC']
      journeys << ['MNY','PKR']
      journeys << ['MTZ','BNC']
      journeys << ['MHQ','ADY']
      journeys << ['MHQ','BNC']
      journeys << ['MYE','BNC']
      journeys << ['MGS','BNC']
      journeys << ['MJE','BNC']
      journeys << ['NRB','BNC']
      journeys << ['NRG','BHI']
      journeys << ['NWM','BNC']
      journeys << ['NPR','CNQ']
      journeys << ['NPR','BNC']
      journeys << ['NPR','CRO']
      journeys << ['NTG','BNC']
      journeys << ['OXL','BNC']
      journeys << ['PKR','MNY']
      journeys << ['PET','BNC']
      journeys << ['RDK','BNC']
      journeys << ['RDK','DIR']
      journeys << ['ROB','BDT1']
      journeys << ['ROB','BNC']
      journeys << ['RKE','BNC']
      journeys << ['RS0','CAB']
      journeys << ['RS0','BNC']
      journeys << ['RS0','GOQ']
      journeys << ['RS0','ZLL']
      journeys << ['SBA','BQY']
      journeys << ['SBE','BNC']
      journeys << ['SBE','CRO']
      journeys << ['SBE','FYG']
      journeys << ['SBE','GAO']
      journeys << ['SYK','BNC']
      journeys << ['SSN','BNC']
      journeys << ['TIQ','BNC']
      journeys << ['TIQ','TBU']
      journeys << ['TBU','TIQ']
      journeys << ['TWG','AHF']
      journeys << ['TWG','BNH']
      journeys << ['TWG','BNC']
      journeys << ['TWG','CRO']
      journeys << ['TWG','GAI']
      journeys << ['TWG','GDQ']
      journeys << ['VGI','BNC']
      journeys << ['WAC','BNC']
      journeys << ['WPT','AIN']
      journeys << ['WPT','BNC']
      journeys << ['WID','BNC']
      journeys << ['WID','GAO']
      journeys << ['ZLL','BNC']
      journeys << ['ZLL','RS0']

      starting_time = Time.zone.now
      puts "Start populate at #{starting_time}"

      journeys.each do |j|
        dep = Station.find_by_code j[0]
        arr = Station.find_by_code j[1]
        puts "#{dep.name} to #{arr.name}"
        Journey.today(dep, arr)
        Journey.today(arr, dep)
      end
    
      puts "Complete populate at #{Time.zone.now}, a duration of #{(Time.zone.now - starting_time).round} seconds, #{journeys.length} journeys loaded."

    end
    
  end
end