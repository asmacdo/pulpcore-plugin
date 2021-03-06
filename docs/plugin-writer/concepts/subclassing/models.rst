.. _subclassing-models:

Models
======

For the most part, models provided by plugin writers are just regular `Django Models
<https://docs.djangoproject.com/en/2.1/topics/db/models/>`_.

.. note::
   One slight variation is that the validation is primarily handled in the Django Rest Framework
   Serializer. ``.clean()`` is not called.

Most plugins will implement:
 * model(s) for the specific content type(s) used in the plugin, should be subclassed from Content model
 * model(s) for the plugin specific remote(s), should be subclassed from Remote model
 * model(s) for the plugin specific publisher(s), should be subclassed from Publisher model


Adding Model Fields
~~~~~~~~~~~~~~~~~~~

Each subclassed Model will typically store attributes that are specific to the content type. These
attributes need to be added to the model as ``fields``. You can use any of Django's field types
for your fields. See the `Django field documentation
<https://docs.djangoproject.com/en/2.1/ref/models/fields/>`_, for more in-depth information on
using these fields.

.. note::
   One of Pulp's goals is to work correctly on multiple databases. It is probably best to avoid
   fields that are not database agnostic. See Database Gotchas below.

The TYPE class attribute is used for filtering purposes.

.. code-block:: python

        class FileContent(Content):
            """
            The "file" content type.

            Fields:
                digest (str): The SHA256 HEX digest.
            """
            TYPE = 'file'
            digest = models.TextField(null=False)


Here we create a new field using use Django's ``TextField``. After adding/modifying a model, you
can make and run database migrations with:


.. code-block:: bash

      pulp-manager makemigrations <plugin_app_label>
      pulp-manager migrate

If you recognize this syntax, it is because pulp-manager is used with the same interace as ``django
admin``, but has additional commands.


Uniqueness
~~~~~~~~~~

Model uniqueness (which will also be used as the natural key) is defined by an inner ``class
Meta``. Pulp Core enforces uniqueness constraints at the database level.

Adding to the simplified ``FileContent`` above:

.. code-block:: python

        class FileContent(Content):
            """
            The "file" content type.
            Content of this type represents a collection of 0 or more files uniquely
            identified by path and SHA256 digest.
            Fields:
                digest (str): The SHA256 HEX digest.
            """

            TYPE = 'file'

            digest = models.TextField(null=False)

            class Meta:
                # Note the comma, this must be a tuple.
                unique_together = ('digest',)

In this example the Content's uniqueness enforced on a single field ``digest``. For a multi-field
uniqueness, simply add other fields.

.. code-block:: python

        class FileContent(Content):
            """
            The "file" content type.
            Content of this type represents a collection of 0 or more files uniquely
            identified by path and SHA256 digest.
            Fields:
                relative_path (str): The file relative path.
                digest (str): The SHA256 HEX digest.
            """

            TYPE = 'file'

            relative_path = models.TextField(null=False)
            digest = models.TextField(null=False)

            class Meta:
                unique_together = (
                   'relative_path',
                   'digest',
                )


The example above ensures that content is unique on ``relative_path`` and ``digest`` together.

Database Gotchas
~~~~~~~~~~~~~~~~

Plugin writers should be aware that certain things may not be database agnostic. Here is a list of a
few things we've found.

Setting ``db_index`` or ``unique`` on a ``TextField`` will cause problems when using MySQL/MariaDB::

   name = models.TextField(db_index=True)  # BLOB/TEXT column 'name' used in key specification without a key length

For this reason, we recommend using ``CharField`` in cases where the field needs to be indexed.

Also, the max length for ``CharField`` in MySQL/MariaDB is 255::

   name = models.CharField(max_length=256)  # MyModel.name: (mysql.E001) MySQL does not allow unique CharFields to have a max_length > 255

In general, we recommend testing your plugins against as many database systems as possible. Travis
or other continuous integration environments can also be used to verify that your plugin is database
agnostic.
