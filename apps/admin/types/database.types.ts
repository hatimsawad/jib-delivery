export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  public: {
    Tables: {
      addresses: {
        Row: {
          address_text: string
          created_at: string
          customer_id: string
          delivery_notes: string | null
          id: string
          label: string
          latitude: number | null
          longitude: number | null
        }
        Insert: {
          address_text: string
          created_at?: string
          customer_id: string
          delivery_notes?: string | null
          id?: string
          label?: string
          latitude?: number | null
          longitude?: number | null
        }
        Update: {
          address_text?: string
          created_at?: string
          customer_id?: string
          delivery_notes?: string | null
          id?: string
          label?: string
          latitude?: number | null
          longitude?: number | null
        }
        Relationships: []
      }
      courier_profiles: {
        Row: {
          approved_at: string | null
          approved_by: string | null
          created_at: string
          is_active: boolean
          phone: string | null
          user_id: string
        }
        Insert: {
          approved_at?: string | null
          approved_by?: string | null
          created_at?: string
          is_active?: boolean
          phone?: string | null
          user_id: string
        }
        Update: {
          approved_at?: string | null
          approved_by?: string | null
          created_at?: string
          is_active?: boolean
          phone?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "courier_profiles_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "courier_profiles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      jib_ai_manager_settings: {
        Row: {
          created_at: string
          id: number
          notification_call_mode: string
          notification_channels: string[]
          notification_email: string
          notification_phone: string
          notification_phone_e164: string
          notification_voice_languages: string[]
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: number
          notification_call_mode?: string
          notification_channels?: string[]
          notification_email: string
          notification_phone: string
          notification_phone_e164: string
          notification_voice_languages?: string[]
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: number
          notification_call_mode?: string
          notification_channels?: string[]
          notification_email?: string
          notification_phone?: string
          notification_phone_e164?: string
          notification_voice_languages?: string[]
          updated_at?: string
        }
        Relationships: []
      }
      jib_ai_manager_health_checks: {
        Row: {
          checked_at: string
          duration_ms: number
          id: string
          issues: Json
          metrics: Json
          status: string
          website_status: number | null
        }
        Insert: {
          checked_at?: string
          duration_ms?: number
          id?: string
          issues?: Json
          metrics?: Json
          status: string
          website_status?: number | null
        }
        Update: {
          checked_at?: string
          duration_ms?: number
          id?: string
          issues?: Json
          metrics?: Json
          status?: string
          website_status?: number | null
        }
        Relationships: []
      }
      jib_ai_manager_events: {
        Row: {
          details: Json
          event_type: string
          fingerprint: string
          first_seen_at: string
          id: string
          last_seen_at: string
          message: string
          occurrence_count: number
          resolved_at: string | null
          severity: string
          status: string
          title: string
        }
        Insert: {
          details?: Json
          event_type: string
          fingerprint: string
          first_seen_at?: string
          id?: string
          last_seen_at?: string
          message: string
          occurrence_count?: number
          resolved_at?: string | null
          severity: string
          status?: string
          title: string
        }
        Update: {
          details?: Json
          event_type?: string
          fingerprint?: string
          first_seen_at?: string
          id?: string
          last_seen_at?: string
          message?: string
          occurrence_count?: number
          resolved_at?: string | null
          severity?: string
          status?: string
          title?: string
        }
        Relationships: []
      }
      jib_ai_manager_notification_outbox: {
        Row: {
          attempts: number
          blocked_reason: string | null
          channel: string
          created_at: string
          event_id: string
          id: string
          next_attempt_at: string | null
          payload: Json
          provider_message_id: string | null
          recipient: string | null
          sent_at: string | null
          status: string
        }
        Insert: {
          attempts?: number
          blocked_reason?: string | null
          channel: string
          created_at?: string
          event_id: string
          id?: string
          next_attempt_at?: string | null
          payload?: Json
          provider_message_id?: string | null
          recipient?: string | null
          sent_at?: string | null
          status?: string
        }
        Update: {
          attempts?: number
          blocked_reason?: string | null
          channel?: string
          created_at?: string
          event_id?: string
          id?: string
          next_attempt_at?: string | null
          payload?: Json
          provider_message_id?: string | null
          recipient?: string | null
          sent_at?: string | null
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "jib_ai_manager_notification_outbox_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "jib_ai_manager_events"
            referencedColumns: ["id"]
          }
        ]
      }
      order_events: {
        Row: {
          actor_id: string | null
          created_at: string
          id: string
          note: string | null
          order_id: string
          status: string
        }
        Insert: {
          actor_id?: string | null
          created_at?: string
          id?: string
          note?: string | null
          order_id: string
          status: string
        }
        Update: {
          actor_id?: string | null
          created_at?: string
          id?: string
          note?: string | null
          order_id?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "order_events_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      order_items: {
        Row: {
          id: string
          line_total_mad: number
          order_id: string
          product_id: string | null
          product_name_snapshot: string
          quantity: number
          unit_price_mad: number
        }
        Insert: {
          id?: string
          line_total_mad: number
          order_id: string
          product_id?: string | null
          product_name_snapshot: string
          quantity: number
          unit_price_mad: number
        }
        Update: {
          id?: string
          line_total_mad?: number
          order_id?: string
          product_id?: string | null
          product_name_snapshot?: string
          quantity?: number
          unit_price_mad?: number
        }
        Relationships: [
          {
            foreignKeyName: "order_items_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      orders: {
        Row: {
          address_id: string | null
          courier_id: string | null
          created_at: string
          customer_id: string
          customer_note: string | null
          delivery_fee_mad: number
          id: string
          payment_method: string
          payment_status: string
          status: string
          store_id: string
          subtotal_mad: number
          total_mad: number
          updated_at: string
        }
        Insert: {
          address_id?: string | null
          courier_id?: string | null
          created_at?: string
          customer_id: string
          customer_note?: string | null
          delivery_fee_mad?: number
          id?: string
          payment_method?: string
          payment_status?: string
          status?: string
          store_id: string
          subtotal_mad: number
          total_mad: number
          updated_at?: string
        }
        Update: {
          address_id?: string | null
          courier_id?: string | null
          created_at?: string
          customer_id?: string
          customer_note?: string | null
          delivery_fee_mad?: number
          id?: string
          payment_method?: string
          payment_status?: string
          status?: string
          store_id?: string
          subtotal_mad?: number
          total_mad?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "orders_address_id_fkey"
            columns: ["address_id"]
            isOneToOne: false
            referencedRelation: "addresses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      products: {
        Row: {
          created_at: string
          description: string | null
          id: string
          image_url: string | null
          is_available: boolean
          name: string
          price_mad: number
          store_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          image_url?: string | null
          is_available?: boolean
          name: string
          price_mad: number
          store_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          image_url?: string | null
          is_available?: boolean
          name?: string
          price_mad?: number
          store_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "products_store_id_fkey"
            columns: ["store_id"]
            isOneToOne: false
            referencedRelation: "stores"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          created_at: string
          full_name: string | null
          id: string
          phone: string | null
          preferred_language: string
          role: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          full_name?: string | null
          id: string
          phone?: string | null
          preferred_language?: string
          role?: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          full_name?: string | null
          id?: string
          phone?: string | null
          preferred_language?: string
          role?: string
          updated_at?: string
        }
        Relationships: []
      }
      stores: {
        Row: {
          address_text: string | null
          category: string
          created_at: string
          description: string | null
          id: string
          is_active: boolean
          is_open: boolean
          latitude: number | null
          longitude: number | null
          name: string
          owner_id: string
          phone: string | null
          updated_at: string
        }
        Insert: {
          address_text?: string | null
          category: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          is_open?: boolean
          latitude?: number | null
          longitude?: number | null
          name: string
          owner_id: string
          phone?: string | null
          updated_at?: string
        }
        Update: {
          address_text?: string | null
          category?: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          is_open?: boolean
          latitude?: number | null
          longitude?: number | null
          name?: string
          owner_id?: string
          phone?: string | null
          updated_at?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_set_courier_active: {
        Args: { p_active: boolean; p_user_id: string }
        Returns: undefined
      }
      admin_set_store_status: {
        Args: { p_is_active: boolean; p_is_open?: boolean; p_store_id: string }
        Returns: undefined
      }
      checkout_order: {
        Args: {
          p_address_id: string
          p_customer_note?: string
          p_items: Json
          p_store_id: string
        }
        Returns: string
      }
      claim_delivery_order: { Args: { p_order_id: string }; Returns: boolean }
      courier_dashboard: {
        Args: never
        Returns: {
          created_at: string
          customer_note: string
          delivery_address: string
          delivery_fee_mad: number
          order_id: string
          status: string
          store_address: string
          store_name: string
          total_mad: number
        }[]
      }
      courier_update_order_status: {
        Args: { p_new_status: string; p_order_id: string }
        Returns: undefined
      }
      jib_ai_manager_monitor_secret: { Args: never; Returns: string }
      jib_order_timeline: {
        Args: { p_order_id?: string | null }
        Returns: {
          order_id: string
          current_stage: string
          order_placed_at: string
          merchant_accepted_at: string | null
          preparation_started_at: string | null
          ready_for_pickup_at: string | null
          courier_assigned_at: string | null
          picked_up_at: string | null
          delivering_at: string | null
          delivered_at: string | null
          elapsed_seconds: number
          expected_remaining_seconds: number | null
          eta_confidence: string
          estimated_delivery_at: string | null
        }[]
      }
      is_jib_admin: { Args: never; Returns: boolean }
      merchant_update_order_status: {
        Args: { p_new_status: string; p_order_id: string }
        Returns: undefined
      }
      register_courier_profile: {
        Args: { p_full_name?: string; p_phone?: string }
        Returns: boolean
      }
      register_merchant_store: {
        Args: {
          p_address?: string
          p_category: string
          p_description?: string
          p_name: string
          p_phone?: string
        }
        Returns: string
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
