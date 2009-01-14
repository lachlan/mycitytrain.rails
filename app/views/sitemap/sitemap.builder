xml.instruct! 
xml.urlset :xmlns => 'http://www.sitemaps.org/schemas/sitemap/0.9' do

	xml.url do
	    xml.loc 'http://mycitytrain.info'
		#xml.lastmod Time.now.xmlschema
		xml.changefreq 'monthly'
		xml.priority '1.0'
	end

	xml.url do
	    xml.loc url_for(:only_path => false, :controller => 'timetable', :action => 'about')
		#xml.lastmod Time.now.xmlschema
		xml.changefreq 'monthly'
		xml.priority '0.1'
	end

end
