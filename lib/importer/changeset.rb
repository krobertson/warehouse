module Importer
  class Changeset < Base
    table 'changesets'
    
    def self.create_from_repository(repository, revision)
      author     = repository.backend.fs.prop(Svn::Core::PROP_REVISION_AUTHOR, revision)
      message    = repository.backend.fs.prop(Svn::Core::PROP_REVISION_LOG,    revision)
      changed_at = repository.backend.fs.prop(Svn::Core::PROP_REVISION_DATE,   revision).utc
      changeset = insert(%w(repository_id revision author message changed_at), [repository.attributes['id'], revision, author, message, changed_at.strftime("%Y-%m-%d %H:%M:%S")])
      Change.create_from_changeset(repository, changeset)
      changeset
    end
  end
end