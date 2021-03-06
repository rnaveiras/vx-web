module ApplicationHelper

  def build_status(build)
    "Build ##{build.number} #{build_status_name build}"
  end

  def build_duration(build)
    if build.started_at && build.finished_at
      distance_of_time_in_words(build.started_at, build.finished_at, include_seconds: true)
    end
  end

  def build_title(build)
    s = build.sha.to_s[0..8]
    s << " ("
    s << build.branch
    s << ")"
  end

  def build_author_url(build)
    link_to build.author, "mailto:#{build.author_email}"
  end

  def github_enabled?
    Rails.configuration.x.github_enabled
  end

  def any_providers_enabled?
    github_enabled?
  end

end
